package funkin;

import base.MusicBeatState.MusicHandler;
import base.system.Conductor;
import base.system.TimingStruct;
import flixel.FlxG;
import flixel.util.FlxSort;
import funkin.CoolUtil;
import funkin.notes.Note;
import haxe.Json;
import openfl.Assets;
import openfl.media.Sound;

using StringTools;

typedef Section =
{
	var startTime:Float;
	var endTime:Float;
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Null<Int>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

/*
	typedef SectionNote = 
	{
	var strumTime:Float;
	var noteData:Int;
	var sustainLength:Float;
}*/
typedef EventNote =
{
	var strumTime:Float;
	var event:String;
	var value1:Dynamic;
	var value2:Dynamic;
}

typedef Song =
{
	var song:String;
	var notes:Array<Section>;
	var events:Array<EventNote>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var player3:String;
	var gfVersion:String;
	var stage:String;
	var arrowSkin:String;
	var validScore:Bool;
}

// improve the network operations
// mix between my fork of forever and the hxs-forever branch of my 0.3.2h repo, although forever uses another type of shit so most of this is from the 0.3.2h branch
class ChartLoader
{
	public static var unspawnedNoteList:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static var netChart:String = null;
	public static var netInst:Sound = null;
	public static var netVoices:Sound = null;

	public static function loadChart(state:MusicHandler, songName:String, difficulty:Int):Song
	{
		Conductor.bpmChangeMap = [];
		unspawnedNoteList = [];
		TimingStruct.reset();

		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		var swagSong:Song = null;
		if (netChart == null)
		{
			// just in case lol
			var formattedSongName:String = Paths.formatString(songName);
			var rawChart:String = Assets.getText(Paths.getPath('$formattedSongName/$formattedSongName${difficultyMap[difficulty][0]}.json', "songs")).trim();
			swagSong = CoolUtil.loadSong(rawChart);

			Conductor.bindSong(state, Paths.inst(songName), swagSong, Paths.voices(songName));
		}
		else
		{
			swagSong = CoolUtil.loadSong(netChart);
			Conductor.bindSong(state, netInst, swagSong, netVoices);
		}

		parseNotes(swagSong);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	private static function parseNotes(swagSong:Song)
	{
		var noteStrumTimes:Map<Int, Array<Float>> = [0 => [], 1 => []];

		if (swagSong.events == null)
		{
			swagSong.events = [
				{
					strumTime: 0,
					event: 'BPM Change',
					value1: swagSong.bpm,
					value2: 0
				}
			];
		}

		var curBPM:Float = swagSong.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (section in swagSong.notes)
		{
			if (section.changeBPM && section.bpm != curBPM)
			{
				curBPM = section.bpm;
				var bpmChange:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: (Conductor.calculateCrochet(curBPM) / 4)
				};
				Conductor.bpmChangeMap.push(bpmChange);
				swagSong.events.push({
					strumTime: totalPos,
					event: 'BPM Change',
					value1: curBPM,
					value2: 0
				});
			}

			var deltaSteps:Int = (section.sectionBeats != null ? Math.round(section.sectionBeats * 4) : section.lengthInSteps);
			totalSteps += deltaSteps;
			totalPos += (Conductor.calculateCrochet(curBPM) / 4) * deltaSteps;

			for (songNotes in section.sectionNotes)
			{
				switch (songNotes[1])
				{
					default:
						{
							var strumTime:Float = songNotes[0];
							var noteData:Int = Std.int(songNotes[1] % 4);
							var hitNote:Bool = section.mustHitSection;

							if (songNotes[1] > 3)
								hitNote = !section.mustHitSection;

							var strumLine:Int = (hitNote ? 1 : 0);
							var holdStep:Float = (songNotes[2] / Conductor.stepCrochet);

							var newNote:Note = new Note(strumTime, noteData, strumLine);
							newNote.mustPress = hitNote;
							unspawnedNoteList.push(newNote);

							if (noteStrumTimes[strumLine].contains(strumTime))
							{
								newNote.doubleNote = true;
								noteStrumTimes[strumLine].push(strumTime);
							}
							noteStrumTimes[strumLine].push(strumTime);
							if (holdStep > 0)
							{
								var floorStep:Int = Std.int(holdStep + 1);
								for (i in 0...floorStep)
								{
									var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * (i + 1)), noteData, strumLine,
										unspawnedNoteList[Std.int(unspawnedNoteList.length - 1)], true);
									sustainNote.mustPress = hitNote;
									sustainNote.parent = newNote;
									newNote.children.push(sustainNote);
									if (i == floorStep - 1)
										sustainNote.isSustainEnd = true;
									unspawnedNoteList.push(sustainNote);

									if (noteStrumTimes[strumLine].contains(strumTime))
									{
										sustainNote.doubleNote = true;
										noteStrumTimes[strumLine].push(strumTime);
									}
									noteStrumTimes[strumLine].push(strumTime);
								}
							}
						}
					case -1:
						{
							for (i in 0...songNotes[1].length)
							{
								var eventDetails:Array<Dynamic> = [songNotes[0], songNotes[1][i][0], songNotes[1][i][1], songNotes[1][i][2]];
								var eventNote:EventNote = {
									strumTime: eventDetails[0],
									event: eventDetails[1],
									value1: eventDetails[2],
									value2: eventDetails[3]
								};
								trace(eventDetails);
								trace(eventNote);

								swagSong.events.push(eventNote);
							}
						}
				}
			}
		}

		unspawnedNoteList.sort(sortByShit);
		parseEvents(swagSong);
		recalculateTimes(swagSong);
		Cache.runGC();
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private static function parseEvents(song:Song)
	{
		var curBPMIdx:Int = 0;
		for (event in song.events)
		{
			trace(event);
			switch (event.event)
			{
				case "BPM Change":
					{
						var bpm:Float = event.value1;
						var beat:Float = event.strumTime;
						var endBeat:Float = Math.POSITIVE_INFINITY;
						TimingStruct.add(beat, bpm, endBeat, 0);

						if (curBPMIdx != 0)
						{
							var dat:TimingStruct = TimingStruct.timings[curBPMIdx - 1];
							dat.endBeat = beat;
							dat.length = ((dat.endBeat - dat.startBeat) / (dat.bpm / 60));
							var step:Float = ((60 / dat.bpm) * 1000) / 4;
							TimingStruct.timings[curBPMIdx].startStep = Math.floor((((dat.endBeat / (dat.bpm / 60)) * 1000) / step));
							TimingStruct.timings[curBPMIdx].startTime = dat.startTime + dat.length;
						}

						curBPMIdx++;
					}

				default:
					trace('${event.event} not supported yet');
			}
		}
	}

	private static function recalculateTimes(song:Song)
	{
		for (i in 0...song.notes.length)
		{
			var section:Section = song.notes[i];
			var currentBeat:Int = 4 * i;
			var currentSeg:TimingStruct = TimingStruct.getTimingAtBeat(currentBeat);
			if (currentSeg == null)
				return;

			var start:Float = (currentBeat - currentSeg.startBeat) / ((currentSeg.bpm) / 60);
			section.startTime = (currentSeg.startTime + start) * 1000;

			if (i != 0)
				song.notes[i - 1].endTime = section.startTime;
			section.endTime = Math.POSITIVE_INFINITY;
		}
	}
}

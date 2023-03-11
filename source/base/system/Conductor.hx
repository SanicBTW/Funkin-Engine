package base.system;

import base.MusicBeatState.MusicHandler;
import base.system.SoundManager.AudioStream;
import funkin.ChartLoader;
import openfl.media.Sound;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	// song shit
	public static var songPosition:Float = 0;
	private static var baseSpeed:Float = 2;
	public static var songSpeed:Float = 2;

	// sections, steps and beats
	public static var sectionPosition:Int = 0;
	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;
	public static var beatDecimal:Float = 0;

	// for resync??
	public static final comparisonThreshold:Float = 30;
	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	// bpm shit
	public static var bpm:Float = 0;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	// the audio shit and the state
	public static var boundSong:AudioStream;
	public static var boundVocals:AudioStream;
	public static var boundState:MusicHandler;

	public function new() {}

	public static function bindSong(newState:MusicHandler, newSong:Sound, SONG:Song, ?newVocals:Sound)
	{
		boundSong = new AudioStream();
		boundSong.audioSource = newSong;
		SoundManager.setSound("inst", boundSong);
		boundVocals = new AudioStream();
		if (newVocals != null)
		{
			boundVocals.audioSource = newVocals;
			SoundManager.setSound("voices", boundVocals);
		}
		boundState = newState;

		baseSpeed = SONG.speed;
		changeBPM(SONG.bpm);

		reset();
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = calculateCrochet(newBPM);
		stepCrochet = (crochet / 4);
		songSpeed = flixel.math.FlxMath.roundDecimal((0.45 * (baseSpeed + ((bpm / 60) / songSpeed) * (stepCrochet / 1000))), 2);
		for (note in ChartLoader.unspawnedNoteList)
		{
			note.updateSustainScale();
		}
	}

	public static function updateTimePosition(elapsed:Float)
	{
		if (boundSong.isPlaying)
		{
			if (songPosition < 0)
				beatDecimal = 0;
			else
			{
				if (TimingStruct.timings.length > 1)
				{
					var data:TimingStruct = TimingStruct.getTimingAtTimestamp(songPosition);
					crochet = ((60 / data.bpm) * 1000);
					flixel.FlxG.watch.addQuick("Conductor timing seg", data.bpm);

					var step:Float = (((60 / data.bpm) * 1000) / 4);
					var startInMS:Float = (data.startTime * 1000);

					beatDecimal = data.startBeat + ((((songPosition / 1000)) - data.startTime) * (data.bpm / 60));
					var intStep:Int = Math.floor(data.startStep + ((songPosition) - startInMS) / step);
					if (intStep >= 0)
					{
						if (intStep > stepPosition)
						{
							for (i in stepPosition...intStep)
							{
								stepPosition++;
								updateBeat();
								stepHit();
							}
						}
						else if (intStep < stepPosition)
						{
							trace("Reset steps at " + songPosition);
							stepPosition = intStep;
							updateBeat();
							stepHit();
						}
					}
				}
				else
				{
					beatDecimal = (((songPosition / 1000))) * (bpm / 60);
					var nextStep:Int = Math.floor(songPosition / stepCrochet);
					if (nextStep >= 0)
					{
						if (nextStep > stepPosition)
						{
							for (i in stepPosition...nextStep)
							{
								stepPosition++;
								updateBeat();
								stepHit();
							}
						}
						else if (nextStep < stepPosition)
						{
							trace("(No BPM Change) Reset steps at " + songPosition);
							stepPosition = nextStep;
							updateBeat();
							stepHit();
						}
					}
					crochet = ((60 / bpm) * 1000);
				}
			}

			songPosition += elapsed * 1000;
		}
	}

	private static function updateBeat()
	{
		lastBeat = beatPosition;
		beatPosition = Math.floor(stepPosition / 4);
	}

	private static function stepHit()
	{
		boundState.stepHit();
		if (stepPosition % 4 == 0)
			boundState.beatHit();
	}

	/*
		private static function updateSteps()
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);
			stepPosition = lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / stepCrochet);
	}*/
	public static function resyncTime()
	{
		trace('Resyncing song time ${boundSong.playbackTime}, $songPosition');
		if (boundVocals != null && boundVocals.audioSource != null)
			boundVocals.stop();

		boundSong.play();
		songPosition = boundSong.playbackTime;
		if (boundVocals != null && boundVocals.audioSource != null)
		{
			boundVocals.playbackTime = songPosition;
			boundVocals.play();
		}
		trace('New song time ${boundSong.playbackTime}, $songPosition');
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static inline function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000;

	public static function reset()
	{
		songPosition = 0;
		stepPosition = 0;
		beatPosition = 0;
		beatDecimal = 0;
		lastStep = -1;
		lastBeat = -1;
	}
}

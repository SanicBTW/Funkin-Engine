package states;

import base.Conductor;
import base.Controls;
import base.FadeTransition;
import base.MusicBeatState;
import base.SoundManager.AudioStream;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import funkin.ChartLoader;
import funkin.CoolUtil;
import funkin.Stage;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;

class PlayTest extends MusicBeatState
{
	public static var SONG:Song;
	public static var stage:Stage;

	public var camHUD:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var strumLines:FlxTypedGroup<StrumLine>;

	private var opponentStrums:StrumLine;
	private var playerStrums:StrumLine;

	@:isVar private var curStep(get, null):Int;

	private function get_curStep():Int
		return Conductor.stepPosition;

	@:isVar private var curBeat(get, null):Int;

	private function get_curBeat():Int
		return Conductor.beatPosition;

	public static var songSpeed:Float = 0;

	public var downscroll:Bool = false;

	private var generatedMusic:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Controls.setActions(NOTES);

		generateSong();

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther);
		FadeTransition.nextCamera = camOther;

		Conductor.boundSong.play();
		Conductor.boundVocals.play();

		strumLines = new FlxTypedGroup<StrumLine>();
		var separation:Float = FlxG.width / 4;
		opponentStrums = new StrumLine((FlxG.width / 2) - separation, 4);
		strumLines.add(opponentStrums);
		playerStrums = new StrumLine((FlxG.width / 2) + separation, 4);
		strumLines.add(playerStrums);
		add(strumLines);
		strumLines.cameras = [camHUD];

		stage = new Stage("stage");
		add(stage);

		super.create();

		Conductor.resyncTime();
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.camera.zoom = FlxMath.lerp(stage.cameraZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
		{
			parseEventColumn(ChartLoader.unspawnedNoteList, function(unspawnNote:Note)
			{
				var strumLine:StrumLine = strumLines.members[unspawnNote.strumLine];
				if (strumLine != null)
					strumLine.push(unspawnNote);
			}, -(16 * Conductor.stepCrochet));

			var downscrollMultiplier:Int = (!downscroll ? 1 : -1) * FlxMath.signOf(songSpeed);

			for (strumLine in strumLines)
			{
				for (receptor in strumLine.receptors)
				{
					if (strumLine.botPlay && receptor.animation.finished)
						receptor.playAnim('static');
				}

				strumLine.allNotes.forEachAlive(function(strumNote:Note)
				{
					if (strumNote.tooLate)
					{
						strumNote.active = false;
						strumNote.visible = false;
					}
					else
					{
						strumNote.visible = true;
						strumNote.active = true;
					}

					strumNote.noteSpeed = Math.abs(songSpeed);
					var roundedSpeed = FlxMath.roundDecimal(strumNote.noteSpeed, 2);

					var baseX = strumLine.receptors.members[Math.floor(strumNote.noteData)].x;
					var baseY = strumLine.receptors.members[Math.floor(strumNote.noteData)].y;
					strumNote.x = baseX + strumNote.offsetX;
					strumNote.y = baseY
						+ strumNote.offsetY
						+ (downscrollMultiplier * -((Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * roundedSpeed)));

					var center:Float = baseY + (Note.swagWidth / 2);
					if (strumNote.isSustain)
					{
						strumNote.y -= ((Note.swagWidth / 2) * downscrollMultiplier);

						if (downscrollMultiplier < 0)
						{
							strumNote.flipY = true;
							if (strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
								&& (strumLine.botPlay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
								swagRect.height = (center - strumNote.y) / strumNote.scale.y;
								swagRect.y = strumNote.frameHeight - swagRect.height;
								strumNote.clipRect = swagRect;
							}
						}
						else if (downscrollMultiplier > 0)
						{
							if (strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
								&& (strumLine.botPlay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
								swagRect.y = (center - strumNote.y) / strumNote.scale.y;
								swagRect.height -= swagRect.y;
								strumNote.clipRect = swagRect;
							}
						}
					}

					if (!strumNote.mustPress && strumNote.wasGoodHit)
						opponentHit(strumNote);

					if ((strumNote.y < -strumNote.height || strumNote.y > FlxG.height + strumNote.height)
						&& (strumNote.tooLate || strumNote.wasGoodHit))
					{
						destroyNote(strumLine, strumNote);
					}
				});
			}

			playerStrums.holdGroup.forEachAlive(function(coolNote:Note)
			{
				if (coolNote.isSustain && coolNote.canBeHit && keys[coolNote.noteData])
				{
					playerHit(coolNote);
				}
			});
		}
	}

	// kade way
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		var data:Int = -1;

		for (i in 0...receptorActionList.length)
		{
			if (receptorActionList[i].toLowerCase() == action.toLowerCase())
				data = i;
		}

		if (data == -1)
		{
			trace('oopsies $action cant be found on action list');
			return;
		}

		if (keys[data])
		{
			trace('already holding $action');
			return;
		}

		keys[data] = true;

		var possibleNoteList:Array<Note> = [];
		var pressedNotes:Array<Note> = [];

		playerStrums.notesGroup.forEachAlive(function(daNote:Note)
		{
			if ((daNote.noteData == data) && !daNote.isSustain && daNote.canBeHit && !daNote.tooLate)
				possibleNoteList.push(daNote);
		});
		possibleNoteList.sort((a, b) -> Std.int(a.stepTime - b.stepTime));

		if (possibleNoteList.length > 0)
		{
			var eligable = true;
			var firstNote = true;
			for (coolNote in possibleNoteList)
			{
				for (noteDouble in pressedNotes)
				{
					if (Math.abs(noteDouble.stepTime - coolNote.stepTime) < 0.1)
						firstNote = false;
					else
						eligable = false;
				}

				if (eligable)
				{
					playerHit(coolNote);
					pressedNotes.push(coolNote);
				}
			}
		}

		if (getReceptor(playerStrums, data).animation.curAnim.name != "confirm")
			getReceptor(playerStrums, data).playAnim('pressed');
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		var data:Int = -1;

		for (i in 0...receptorActionList.length)
		{
			if (receptorActionList[i].toLowerCase() == action.toLowerCase())
				data = i;
		}

		if (data == -1)
			return;

		keys[data] = false;

		getReceptor(playerStrums, data).playAnim('static');
	}

	override public function beatHit()
	{
		super.beatHit();

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
		}
	}

	private function opponentHit(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 1;

		var time:Float = 0.15;
		if (note.isSustain && !note.isSustainEnd)
			time += 0.15;
		receptorPlayAnim(true, note.noteData, time);

		if (!note.isSustain)
			destroyNote(opponentStrums, note);
	}

	private function playerHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			getReceptor(playerStrums, note.noteData).playAnim('confirm');
			if (note.isSustain && note.isSustainEnd)
				getReceptor(playerStrums, note.noteData).playAnim('pressed');

			note.wasGoodHit = true;
			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
		}
	}

	private function playerMissPress(direction:Int = 1)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;
	}

	private function receptorPlayAnim(opponent:Bool, noteData:Int, time:Float)
	{
		var receptor:Receptor = getReceptor(opponent ? opponentStrums : playerStrums, noteData);
		if (receptor != null)
		{
			receptor.playAnim('confirm', true);
			receptor.resetAnim = time;
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function destroyNote(strumLine:StrumLine, note:Note)
	{
		note.active = false;
		note.exists = false;

		note.kill();
		strumLine.allNotes.remove(note, true);
		(note.isSustain ? strumLine.holdGroup.remove(note, true) : strumLine.notesGroup.remove(note, true));
		note.destroy();
	}

	public function parseEventColumn(eventColumn:Array<Dynamic>, functionToCall:Dynamic->Void, ?timeDelay:Float = 0)
	{
		// check if there even are events to begin with
		if (eventColumn.length > 0)
		{
			while (eventColumn[0] != null && (eventColumn[0].stepTime + timeDelay / Conductor.stepCrochet) <= Conductor.stepPosition)
			{
				if (functionToCall != null)
					functionToCall(eventColumn[0]);
				eventColumn.splice(eventColumn.indexOf(eventColumn[0]), 1);
			}
		}
	}

	private function generateSong():Void
	{
		SONG = ChartLoader.loadChart(this, "oversight", 2);
		songSpeed = SONG.speed;

		generatedMusic = true;
	}
}

package funkin;

import funkin.ChartLoader;
import haxe.Json;

using StringTools;

class CoolUtil
{
	public static inline function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	public static function onLoadJson(songJson:Song)
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:Section = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push({
							strumTime: note[0],
							event: note[2],
							value1: note[3],
							value2: note[4]
						});
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}
	}

	public static function loadSong(rawInput:String):Song
	{
		while (!rawInput.endsWith("}"))
		{
			rawInput = rawInput.substr(0, rawInput.length - 1);
		}

		var songJson:Song = parseJSONshit(rawInput);
		onLoadJson(songJson);
		return songJson;
	}

	private static function parseJSONshit(rawJson:String):Song
	{
		var swagShit:Song = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}

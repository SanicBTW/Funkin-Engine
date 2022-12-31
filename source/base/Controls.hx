package base;

import flixel.FlxG;
import haxe.ds.StringMap;
import lime.app.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

// From FNF-Forever-Engine (My fork)
class Controls
{
	public static var onActionPressed:Event<String->Void> = new Event<String->Void>();
	public static var onActionReleased:Event<String->Void> = new Event<String->Void>();

	private static final keyCodes:Map<Int, String> = [
		65 => "A", 66 => "B", 67 => "C", 68 => "D", 69 => "E", 70 => "F", 71 => "G", 72 => "H", 73 => "I", 74 => "J", 75 => "K", 76 => "L", 77 => "M",
		78 => "N", 79 => "O", 80 => "P", 81 => "Q", 82 => "R", 83 => "S", 84 => "T", 85 => "U", 86 => "V", 87 => "W", 88 => "X", 89 => "Y", 90 => "Z",
		48 => "0", 49 => "1", 50 => "2", 51 => "3", 52 => "4", 53 => "5", 54 => "6", 55 => "7", 56 => "8", 57 => "9", 33 => "Page Up", 34 => "Page Down",
		36 => "Home", 35 => "End", 45 => "Insert", 27 => "Escape", 189 => "-", 187 => "+", 46 => "Delete", 8 => "Backspace", 219 => "[", 221 => "]",
		220 => "\\", 20 => "Caps Lock", 186 => ";", 222 => "\"", 13 => "Enter", 16 => "Shift", 188 => ",", 190 => ".", 191 => "/", 192 => "`", 17 => "Ctrl",
		18 => "Alt", 32 => "Space", 38 => "Up", 40 => "Down", 37 => "Left", 39 => "Right", 9 => "Tab", 301 => "Print Screen", 112 => "F1", 113 => "F2",
		114 => "F3", 115 => "F4", 116 => "F5", 117 => "F6", 118 => "F7", 119 => "F8", 120 => "F9", 121 => "F10", 122 => "F11", 123 => "F12", 96 => "Numpad 0",
		97 => "Numpad 1", 98 => "Numpad 2", 99 => "Numpad 3", 100 => "Numpad 4", 101 => "Numpad 5", 102 => "Numpad 6", 103 => "Numpad 7", 104 => "Numpad 8",
		105 => "Numpad 9", 109 => "Numpad -", 107 => "Numpad +", 110 => "Numpad .", 106 => "Numpad *"
	];

	private static var actions:StringMap<Array<Null<Int>>> = [
		"ui_left" => [Keyboard.A, Keyboard.LEFT],
		"ui_down" => [Keyboard.S, Keyboard.DOWN],
		"ui_up" => [Keyboard.W, Keyboard.UP],
		"ui_right" => [Keyboard.D, Keyboard.RIGHT],
		"note_left" => [Keyboard.A, Keyboard.LEFT],
		"note_down" => [Keyboard.S, Keyboard.DOWN],
		"note_up" => [Keyboard.W, Keyboard.UP],
		"note_right" => [Keyboard.D, Keyboard.RIGHT],
		"confirm" => [Keyboard.SPACE, Keyboard.ENTER],
		"back" => [Keyboard.BACKSPACE, Keyboard.ESCAPE],
		"vol_up" => [187 /* mf wasnt in the keyboard list dunno why lol*/, Keyboard.NUMPAD_ADD],
		"vol_down" => [Keyboard.MINUS, Keyboard.NUMPAD_SUBTRACT],
		"mute" => [Keyboard.NUMBER_0, Keyboard.NUMPAD_0]
	];

	public static var keyPressed:Array<Int> = [];

	// TODO: set custom actions based on the users save data
	public static function init()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	public static function keyCodeToString(keyCode:Null<Int>):String
		return keyCode != null ? keyCodes.get(keyCode) : "None";

	public static function isActionPressed(action:String):Bool
	{
		for (actionKey in actions.get(action))
		{
			for (keyP in keyPressed)
			{
				if (actionKey == keyP)
					return true;
			}
		}
		return false;
	}

	public static function getActionFromKey(key:Int):Null<String>
	{
		for (actionName => actionKeys in actions)
		{
			for (actionKey in actionKeys)
			{
				if (key == actionKey)
					return actionName;
			}
		}
		return null;
	}

	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && FlxG.state.active)
		{
			if (!keyPressed.contains(evt.keyCode))
			{
				keyPressed.push(evt.keyCode);

				var pressedAction:Null<String> = getActionFromKey(evt.keyCode);
				if (pressedAction != null)
					onActionPressed.dispatch(pressedAction);
			}
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && FlxG.state.active)
		{
			if (keyPressed.contains(evt.keyCode))
			{
				keyPressed.remove(evt.keyCode);

				var releasedAction:Null<String> = getActionFromKey(evt.keyCode);
				if (releasedAction != null)
					onActionReleased.dispatch(releasedAction);
			}
		}
	}
}

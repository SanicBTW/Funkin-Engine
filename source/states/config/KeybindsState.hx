package states.config;

import base.Controls;
import base.MusicBeatState;
import base.SaveData;
import base.ScriptableState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.Character;
import funkin.Stage;
import haxe.ds.StringMap;
import states.config.ConfigObjects.KeybindSelector;

using StringTools;

class KeybindsState extends MusicBeatState
{
	var cam:FlxCamera;
	var stage:Stage;
	var bf:Character;

	var currentActions:FlxTypedGroup<KeybindSelector>;
	var bindedActions:FlxTypedGroup<KeybindSelector>;

	var actions:Array<ActionType> = [UI, NOTES];
	var curActions(default, set):Int = 0;
	var curSelected(default, set):Int = 0;
	var curKeySelected(default, set):Int = 0;

	var instance:KeybindsState;

	var canPress:Bool = true;
	var adding:Bool = false;
	var listening:Bool = false;
	var currentState(default, set):SelectionState = SELECTING;

	private function set_currentState(newState:SelectionState):SelectionState
	{
		trace("NEW STATE " + newState);

		var currentObject:KeybindSelector = currentActions.members[curSelected];
		if (newState == SELECTING)
		{
			for (i in 0...bindedActions.length)
			{
				bindedActions.remove(bindedActions.members[0], true);
			}
			currentObject.forceX = 30;
			currentObject.yAdd = 0;
		}

		if (newState == LISTING)
		{
			currentObject.forceX = 640;
			currentObject.yAdd = -250;
			if (bindedActions.length <= 0)
				regenBinded(currentObject);

			if (bindedActions.length > 0)
				bindedActions.members[curKeySelected].scale.set(1, 1);
		}

		if (newState == WAITING)
		{
			bindedActions.members[curKeySelected].scale.set(1.1, 1.1);
		}

		return currentState = newState;
	}

	private function set_curSelected(val:Int):Int
	{
		curSelected += val;

		if (curSelected < 0)
			curSelected = currentActions.length - 1;
		if (curSelected >= currentActions.length)
			curSelected = 0;

		var the:Int = 0;

		for (item in currentActions.members)
		{
			item.targetY = the - curSelected;
			item.scale.set(0.7, 0.7);
			item.alpha = 0.6;
			the++;

			if (item.ID == curSelected)
			{
				item.scale.set(0.9, 0.9);
				item.alpha = 1;
			}
		}

		return val;
	}

	private function set_curKeySelected(val:Int):Int
	{
		curKeySelected += val;

		if (curKeySelected < 0)
			curKeySelected = bindedActions.length - 1;
		if (curKeySelected >= bindedActions.length)
			curKeySelected = 0;

		var the:Int = 0;

		for (item in bindedActions.members)
		{
			item.targetY = the - curKeySelected;
			item.alpha = 0.4;
			the++;

			if (item.ID == curKeySelected)
				item.alpha = 1;
		}

		return val;
	}

	private function set_curActions(val:Int):Int
	{
		for (i in 0...currentActions.members.length)
		{
			currentActions.remove(currentActions.members[0], true);
		}

		curActions += val;

		if (curActions < 0)
			curActions = actions.length - 1;
		if (curActions >= actions.length)
			curActions = 0;

		regenActions(actions[curActions]);

		return val;
	}

	override function create()
	{
		instance = this;

		stage = new Stage("stage");
		add(stage);

		currentActions = new FlxTypedGroup<KeybindSelector>();
		bindedActions = new FlxTypedGroup<KeybindSelector>();
		add(bindedActions);
		add(currentActions);

		curActions = 0;

		super.create();
	}

	// Sorry im more of a runtime mf
	private function regenActions(regenGroup:ActionType)
	{
		var i:Int = 0;
		var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, regenGroup);
		for (action => keyArr in actionMap)
		{
			var newSelector:KeybindSelector = new KeybindSelector(0, (70 * i) + 30, '$action\nBinds: [${keyArr.length}]');
			newSelector.targetY = i;
			newSelector.ID = i;
			newSelector.forceX = 30;
			newSelector.action = action;
			currentActions.add(newSelector);
			i++;
		}
		curSelected = currentActions.length + 1;
	}

	private function regenBinded(object:KeybindSelector)
	{
		var i:Int = 0;
		var actionKeys:Array<Null<Int>> = Reflect.field(Controls, actions[curActions]).get(object.action);
		for (keyCode in actionKeys)
		{
			var newKeySelector:KeybindSelector = new KeybindSelector(0, (50 * i) + 10, 'Keybind ${i}: ', Std.int(object.width * 1.8), null,
				Controls.keyCodeToString(keyCode));
			newKeySelector.targetY = i;
			newKeySelector.ID = i;
			newKeySelector.baseKey = Controls.keyCodeToString(keyCode);
			newKeySelector.forceX = (FlxG.width / 2) - (object.width / 2);
			bindedActions.add(newKeySelector);
			i++;
		}

		var addKey:KeybindSelector = new KeybindSelector(0, (50 * i) + 10, 'Add bind', Std.int(object.width * 1.8), null);
		addKey.targetY = i;
		addKey.ID = i;
		addKey.bitText.x = (FlxG.width / 2) - (addKey.width / 2) - 25;
		addKey.forceX = (FlxG.width / 2) - (object.width / 2);
		bindedActions.add(addKey);

		curKeySelected = bindedActions.length + 1;
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (currentState)
		{
			case SELECTING:
				{
					switch (action)
					{
						case "ui_up":
							curSelected = -1;
						case "ui_down":
							curSelected = 1;
						case "ui_left":
							curActions = -1;
						case "ui_right":
							curActions = 1;
						case "confirm":
							{
								currentState = LISTING;
								canPress = false;
							}
						case "back":
							{
								SaveData.saveSettings();
								ScriptableState.switchState(new MainState());
							}
					}
				}
			case LISTING:
				{
					switch (action)
					{
						case "ui_up":
							curKeySelected = -1;
						case "ui_down":
							curKeySelected = 1;
						case "back":
							{
								currentState = SELECTING;
								canPress = false;
							}
						case "confirm":
							{
								if (bindedActions.members[curKeySelected].bitText.text == "Add bind")
								{
									var actionObject:KeybindSelector = currentActions.members[curSelected];
									var currentKeyObject:KeybindSelector = bindedActions.members[curKeySelected];
									var keyObject:KeybindSelector = bindedActions.members[curKeySelected - 1];
									var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, actions[curActions]);

									var newKeySelector:KeybindSelector = new KeybindSelector(0, 0, 'Keybind ${keyObject.ID + 1}: ',
										Std.int(actionObject.width * 1.8), null, "?");
									newKeySelector.targetY = currentKeyObject.targetY;
									newKeySelector.ID = keyObject.ID + 1;
									newKeySelector.baseKey = "";
									newKeySelector.forceX = (FlxG.width / 2) - (actionObject.width / 2);

									currentKeyObject.ID = newKeySelector.ID + 1;
									currentKeyObject.targetY = newKeySelector.ID + 1;

									bindedActions.insert(bindedActions.length - 1, newKeySelector);

									adding = true;
								}

								currentState = WAITING;
								listening = true;
								canPress = false;

								/*
									if (bindedActions.members[curKeySelected].subBitText != null)
										bindedActions.members[curKeySelected].subBitText.text = "?"; */
							}
					}
				}
			case WAITING:
				{
					if (action == "back")
					{
						listening = false;
						currentState = LISTING;
						if (bindedActions.members[curKeySelected].subBitText != null)
							bindedActions.members[curKeySelected].subBitText.text = bindedActions.members[curKeySelected].baseKey;
					}
				}
		}
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		canPress = true;
	}

	override public function update(elapsed:Float)
	{
		// keyCode 13 seems to be Enter/Return
		if (currentState == WAITING && listening && !adding && Controls.keyPressed.length > 0 && Controls.keyPressed[0] != 13)
		{
			var actionObject:KeybindSelector = currentActions.members[curSelected];
			var keyObject:KeybindSelector = bindedActions.members[curKeySelected];
			var newKey:Null<String> = Controls.keyCodeToString(Controls.keyPressed[0]);
			var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, actions[curActions]);

			actionMap.get(actionObject.action)[keyObject.ID] = Controls.keyPressed[0];
			keyObject.subBitText.text = (newKey != null) ? newKey : keyObject.baseKey;
			// this code should be when adding
			// actionMap.get(actionObject.action).push(Controls.keyPressed[0]);
			// actionObject.bitText.text = '${actionObject.action}\nBinds: [${actionMap.get(actionObject.action).length}]';

			listening = false;
			currentState = LISTING;
		}

		super.update(elapsed);
	}
}

enum abstract ActionType(String) to String
{
	var UI = "uiActions";
	var NOTES = "noteActions";
}

enum SelectionState
{
	SELECTING;
	LISTING;
	WAITING;
}

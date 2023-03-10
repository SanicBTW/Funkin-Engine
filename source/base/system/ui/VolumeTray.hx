package base.system.ui;

import base.system.SoundManager;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFormat;

// Based off FlxSoundTray
// Make points use FlxPoint for better recycling?
// Move draw operations to a class extending Sprite (openfl) on CircularSprite
class VolumeTray extends Sprite
{
	// If its active then update, apparently its expensive to update?
	public var active:Bool = false;

	// Time visible
	private var _visibleTime:Float = 0.0;

	// Sizes
	private var _width:Int = 120;
	private var _height:Int = 35;
	private var _defaultScale:Float = 2.0;

	// For lerp
	private var targetX:Float = 0.0;
	private var targetY:Float = 0.0;

	// The volume tray gets updated on the update event of the application, uses FlxG elapsed to get the time since last frame, apparently it does the same on FlxGame but yeah
	private var elapsed(get, null):Float;

	private function get_elapsed():Float
		return FlxG.elapsed;

	// Sprites
	private var _volTracker:TextField; // temp and the vol tracker?
	private var _volBar:Bitmap;

	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		y = -Lib.current.stage.stageHeight;

		var bg:Bitmap = new Bitmap(new BitmapData(_width, _height, true, 0x7F000000));
		screenCenter();
		addChild(bg);

		// Not kept in variable because this one doesn't update
		var volText:TextField = new TextField();
		setTxtFieldProperties(volText);
		volText.text = "Volume";
		volText.defaultTextFormat.align = LEFT;
		volText.x = 5;
		addChild(volText);

		// This one gets updated when volume changes
		_volTracker = new TextField();
		setTxtFieldProperties(_volTracker);
		_volTracker.text = '${SoundManager.globalVolume * 100}%';
		_volTracker.defaultTextFormat.align = RIGHT;
		_volTracker.x = (_width - _volTracker.textWidth) - 10;
		addChild(_volTracker);

		_volBar = new Bitmap(new BitmapData(_width - 10, 5, false, FlxColor.WHITE));
		_volBar.x = 5;
		_volBar.y = (_height - _volBar.height) - 5;
		addChild(_volBar);
	}

	public function update()
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 5.125), 0, 1);

		y = FlxMath.lerp(targetY, y, lerpVal);
		_volBar.scaleX = FlxMath.lerp(SoundManager.globalVolume, _volBar.scaleX, lerpVal);

		if (_visibleTime > 0)
			_visibleTime -= elapsed;
		else if (y > -height)
		{
			targetY -= elapsed * FlxG.height * _defaultScale;

			if (y <= -height)
			{
				visible = false;
				active = false;
			}
		}
	}

	public function show()
	{
		_visibleTime = 1.8;
		targetY = 0;
		_volTracker.text = '${Math.floor(SoundManager.globalVolume * 100)}%';
		visible = true;
		active = true;
	}

	public function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}

	private function setTxtFieldProperties(field:TextField)
	{
		field.width = _width;
		field.height = _height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.embedFonts = true;
		field.y = 5;
		field.defaultTextFormat = new TextFormat(Assets.getFont(Paths.font("funkin.otf")).fontName, 10, 0xFFFFFF);
	}
}

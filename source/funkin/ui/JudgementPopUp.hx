package funkin.ui;

import base.system.Conductor;
import base.ui.Sprite.DepthSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;

class JudgementPopUp extends FlxSpriteGroup
{
	private var comboSprite:DepthSprite;
	private var comboGhostTwn:FlxTween;

	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
		antialiasing = SaveData.antialiasing;

		comboSprite = new DepthSprite();
		comboSprite.loadGraphic(Paths.image('combo'), true, 100, 140);
		comboSprite.alpha = 0;
		comboSprite.antialiasing = antialiasing;
		comboSprite.setGraphicSize(Std.int(comboSprite.width * 0.5));
		comboSprite.updateHitbox();
		add(comboSprite);
	}

	public function popCombo(number:String, marv:Bool, ?zDepth:Float = 0)
	{
		check(comboSprite, comboGhostTwn);
		comboSprite.zDepth = zDepth;

		trace(number);
		if (!comboSprite.animation.exists(number))
			comboSprite.animation.add(number, [(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!marv ? 0 : 11)], 0, false);
		comboSprite.animation.play(number);

		var clone:FlxSprite = getClone(comboSprite);
		clone.scale.set(1.25, 1.25);
		insert(members.indexOf(comboSprite), clone);
		comboGhostTwn = FlxTween.tween(clone, {"scale.x": 1, "scale.y": 1}, 0.1, {
			onComplete: (_) ->
			{
				comboGhostTwn = null;
			},
			startDelay: Conductor.crochet * 0.00125
		});
	}

	private function check(sprite:DepthSprite, twn:FlxTween)
	{
		if (sprite.alpha != 1)
			sprite.alpha = 1;

		if (twn != null)
			twn.cancel();
	}

	private function getClone(sprite:DepthSprite):FlxSprite
	{
		var clone:FlxSprite = sprite.clone();
		clone.frames = sprite.frames;
		clone.animation.copyFrom(sprite.animation);

		clone.alpha = 0.6;
		clone.setPosition(sprite.x, sprite.y);
		clone.antialiasing = sprite.antialiasing;
		clone.setGraphicSize(Std.int(sprite.width));
		clone.updateHitbox();

		clone.animation.play(sprite.animation.curAnim.name);

		return clone;
	}
}

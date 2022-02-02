package;

import sys.FileSystem;
import sys.io.File;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using StringTools;

typedef StagePiece =
{
	var type:String;
	var id:String;
	var image:String;
	var animName:String;
	var fps:Int;
	var position:Array<Int>;
	var scale:Array<Float>;
	var scrollFactor:Array<Float>;
}

typedef StageData =
{
	var camZoom:Float;
	var camPos:Array<Int>;
	var bfPos:Array<Int>;
	var gfPos:Array<Int>;
	var dadPos:Array<Int>;
	var hideGirlfriend:Bool;
	var pieces:Array<StagePiece>;
	var events:String;
}

class Stage extends MusicBeatState
{
	public var curStage:String = '';
	public var stageJson:StageData = null;
	public var camZoom:Float; // The zoom of the camera to have at the start of the game
	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

	function stagePieceStatic(identifier:String, imageName:String, pos:Array<Int>, scale:Array<Float>, scrollFactor:Array<Float>)
	{
		var piece:FlxSprite = new FlxSprite(pos[0], pos[1]).loadGraphic(Paths.image('stages/' + curStage + '/' + imageName));
		piece.antialiasing = FlxG.save.data.antialiasing;
		if (scrollFactor != null)
			piece.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
		if (scale != null)
		{
			piece.setGraphicSize(Std.int(piece.width * scale[0]), Std.int(piece.height * scale[1]));
			piece.updateHitbox();
		}
		piece.active = false;
		swagBacks[identifier] = piece;
		toAdd.push(piece);
	}

	function stagePieceAnimated(identifier:String, imageName:String, animationName:String, animationSpeed:Int, pos:Array<Int>, scale:Array<Float>, scrollFactor:Array<Float>)
	{
		var piece:FlxSprite = new FlxSprite(pos[0], pos[1]);
		piece.frames = Paths.getSparrowAtlas('stages/' + curStage + '/' + imageName);
		piece.animation.addByPrefix('idle', animationName, animationSpeed, true);
		piece.animation.play('idle');
		piece.antialiasing = FlxG.save.data.antialiasing;
		if (scrollFactor != null)
			piece.scrollFactor.set(scrollFactor[0], scrollFactor[1]);
		if (scale != null)
		{
			piece.setGraphicSize(Std.int(piece.width * scale[0]), Std.int(piece.height * scale[1]));
			piece.updateHitbox();
		}
		swagBacks[identifier] = piece;
		toAdd.push(piece);
	}

	public function new(daStage:String)
	{
		super();
		this.curStage = daStage;
		camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one

		if (!Paths.doesTextAssetExist(Paths.json('stages/' + daStage)))
			this.curStage = 'stage';

		Debug.logInfo('Generating stage (' + this.curStage + ') from JSON data...');

		stageJson = cast Paths.loadJSON('stages/' + this.curStage);
		if (stageJson.gfPos == null)
			stageJson.gfPos = [0, 0];
		camZoom = stageJson.camZoom;

		var stagePieces:Array<StagePiece> = stageJson.pieces;
		for (i in 0...stagePieces.length)
		{
			var piece = stagePieces[i];
			var identifier = piece.id;
			if (identifier == null)
				identifier = piece.image;

			switch ( piece.type )
			{
				case 'static':
					stagePieceStatic( identifier, piece.image, piece.position, piece.scale, piece.scrollFactor );
				case 'animated':
					stagePieceAnimated( identifier, piece.image, piece.animName, piece.fps, piece.position, piece.scale, piece.scrollFactor );
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function stepHit()
	{
		super.stepHit();

		if (!PlayStateChangeables.Optimize)
		{
			var array = slowBacks[curStep];
			if (array != null && array.length > 0)
			{
				if (hideLastBG)
				{
					for (bg in swagBacks)
					{
						if (!array.contains(bg))
						{
							var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
								onComplete: function(tween:FlxTween):Void
								{
									bg.visible = false;
								}
							});
						}
					}
					for (bg in array)
					{
						bg.visible = true;
						FlxTween.tween(bg, {alpha: 1}, tweenDuration);
					}
				}
				else
				{
					for (bg in array)
						bg.visible = !bg.visible;
				}
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (FlxG.save.data.distractions && animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
				bg.animation.play('idle', true);
		}
	}
}

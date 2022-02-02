package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var characterPosition:Array<Int> = [0, 0];
	public var cameraPosition:Array<Int> = [0, 0];
	public var isPlayer:Bool = false;
	public var isPlayerCharacter:Bool = false;
	public var curCharacter:String = 'bf';
	public var barColor:FlxColor;
	public var gameOverCharacter:String = 'bf-dead';
	public var importantAnimation:Bool = false;
	public var danceType:String = 'normalDance';
	public var icon:CharacterIcon = null;

	public var holdTimer:Float = 0;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		barColor = isPlayer ? 0xFF66FF33 : 0xFFFF0000;
		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		var tex:FlxAtlasFrames;
		antialiasing = FlxG.save.data.antialiasing;

		parseDataFile();

		if (isPlayerCharacter)
			dance();

		if (isPlayer && frames != null)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!isPlayerCharacter)
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}
	}

	function parseDataFile()
	{
		Debug.logInfo('Generating character (${curCharacter}) from JSON data...');

		// Load the data from JSON and cast it to a struct we can easily read.
		var jsonData = Paths.loadJSON('characters/${curCharacter}');
		if (jsonData == null)
		{
			Debug.logError('Failed to parse JSON data for character ${curCharacter}');
			return;
		}

		var data:CharacterData = cast jsonData;
		characterPosition = data.position;
		cameraPosition = data.camPosition;

		if (data.gameOverCharacter == null)
		{
			if (curCharacter.endsWith('-dead'))
				gameOverCharacter = curCharacter;
			else
				gameOverCharacter = curCharacter + '-dead';
		}
		else
			gameOverCharacter = data.gameOverCharacter;

		var tex:FlxAtlasFrames = Paths.getSparrowAtlas(data.asset, 'shared', true);
		frames = tex;
		if (frames != null)
			for (anim in data.animations)
			{
				var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
				var looped = anim.looped == null ? false : anim.looped;
				var flipX = anim.flipX == null ? false : anim.flipX;
				var flipY = anim.flipY == null ? false : anim.flipY;

				if (anim.frameIndices != null)
				{
					animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", frameRate, looped, flipX, flipY);
				}
				else
				{
					animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
				}

				animOffsets[anim.name] = anim.offsets == null ? [0, 0] : anim.offsets;
			}

		if (data.barColor != null)
			barColor = FlxColor.fromString(data.barColor);

		playAnim(data.startingAnim);
		if (data.startingAnimIsSpecial != null)
			importantAnimation = data.startingAnimIsSpecial;
		if (data.flipX != null)
			flipX = data.flipX;

		if (data.icon == null)
			icon = { image: curCharacter, frames: [0, 1] };
		else
			icon = data.icon;

		if (data.isPlayerCharacter != null)
			isPlayerCharacter = data.isPlayerCharacter;

		if (data.danceType != null)
			danceType = data.danceType;
	}

	override function update(elapsed:Float)
	{
		if (!isPlayer && !curCharacter.endsWith('dead') )
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				dance();
				holdTimer = 0;
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false, altAnim:Bool = false)
	{
		if (!debugMode && !importantAnimation)
		{
			switch (danceType)
			{
				case 'headBop':
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');

				case 'forcedDance':
					if (altAnim && animation.getByName('idle-alt') != null)
						playAnim('idle-alt', true);
					else
						playAnim('idle', true);

				default:
					if (altAnim && animation.getByName('idle-alt') != null)
						playAnim('idle-alt', forced);
					else
						playAnim('idle', forced);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		importantAnimation = false;
		if (AnimName.endsWith('alt') && animation.getByName(AnimName) == null)
		{
			#if debug
			FlxG.log.warn(['Such alt animation doesnt exist: ' + AnimName]);
			#end
			AnimName = AnimName.split('-')[0];
		}

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}

typedef CharacterData =
{
	var name:String;
	var asset:String;
	var startingAnim:String;
	var ?startingAnimIsSpecial:Bool;
	var ?danceType:String;
	var ?gameOverCharacter:String;
	var ?icon:CharacterIcon;

	/**
	 * The color of this character's health bar.
	 */
	var barColor:String;

	var position:Array<Int>;
	var camPosition:Array<Int>;
	var animations:Array<AnimationData>;
	var ?isPlayerCharacter:Bool;
	var ?flipX:Bool;
}

typedef CharacterIcon =
{
	var image:String;
	var frames:Array<Int>;
}

typedef AnimationData =
{
	var name:String;
	var prefix:String;
	var ?offsets:Array<Int>;

	/**
	 * Whether this animation is looped.
	 * @default false
	 */
	var ?looped:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	/**
	 * The frame rate of this animation.
	 		* @default 24
	 */
	var ?frameRate:Int;

	var ?frameIndices:Array<Int>;
}

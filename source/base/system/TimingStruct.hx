package base.system;

// From Kade Engine, once I understand all of this, I will try to make it my way
class TimingStruct
{
	public static var timings:Array<TimingStruct> = [];

	// Each class vars
	public var bpm:Float = 0;

	public var startBeat:Float = 0; // Beats
	public var startStep:Int = 0; // Bad measures
	public var endBeat:Float = Math.POSITIVE_INFINITY; // Beats
	public var startTime:Float = 0; // Seconds

	public var length:Float = Math.POSITIVE_INFINITY; // Beats

	public function new(startBeat:Float, bpm:Float, endBeat:Float, offset:Float)
	{
		this.bpm = bpm;
		this.startBeat = startBeat;
		if (endBeat != -1)
			this.endBeat = endBeat;
		startTime = offset;
	}

	public static function reset()
		timings = [];

	public static function add(startBeat:Float, bpm:Float, endBeat:Float, offset:Float)
		timings.push(new TimingStruct(startBeat, bpm, endBeat, offset));

	public static function getTimingAtTimestamp(msTime:Float):TimingStruct
	{
		for (timing in timings)
		{
			if (msTime >= timing.startTime * 1000 && msTime < (timing.startTime + timing.length) * 1000)
				return timing;
		}

		return null;
	}

	public static function getTimingAtBeat(beat:Float)
	{
		for (timing in timings)
		{
			if (timing.startBeat <= beat && timing.endBeat >= beat)
				return timing;
		}

		return null;
	}

	public static function getBeatFromTime(time:Float)
	{
		var beat:Float = -1.0;
		var seg:TimingStruct = getTimingAtTimestamp(time);

		if (seg != null)
			beat = seg.startBeat + (((time / 1000) - seg.startTime) * (seg.bpm / 60));

		return beat;
	}

	public static function getTimeFromBeat(beat:Float)
	{
		var time:Float = -1.0;
		var seg:TimingStruct = getTimingAtBeat(beat);

		if (seg != null)
			time = seg.startTime + ((beat - seg.startBeat) / (seg.bpm / 60));

		return time * 1000;
	}
}

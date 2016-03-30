module ggplotd.bounds;

/// Point with x and y value
struct Point
{
    /// x value
    double x;
    /// y value
    double y;

    /// Constructor taking x and y value
    this(double my_x, double my_y)
    {
        x = my_x;
        y = my_y;
    }

    /// Constructor taking a string holding the x and y value separated by a comma
    this(string value)
    {
        import std.conv : to;
        import std.range : split;

        auto coords = value.split(",");
        assert(coords.length == 2);
        x = to!double(coords[0]);
        y = to!double(coords[1]);
    }

    unittest
    {
        assert(Point("1.0,0.1") == Point(1.0, 0.1));
    }

    /// Test whether two points are equal to each other
    bool opEquals(in Point point) const
    {
        return point.x == x && point.y == y;
    }

}

/// Bounds struct holding the bounds (min_x, max_x, min_y, max_y)
struct Bounds
{
    /// Lower x limit
    double min_x;
    /// Upper x limit
    double max_x;
    /// Lower y limit
    double min_y;
    /// Upper y limit
    double max_y;

    /// Constructor taking the x and y limits
    this(double my_min_x, double my_max_x, double my_min_y, double my_max_y)
    {
        min_x = my_min_x;
        max_x = my_max_x;
        min_y = my_min_y;
        max_y = my_max_y;
    }

    /// Constructor taking the x and y limits separated by a comma
    this(string value)
    {
        import std.conv : to;
        import std.range : split;
        import std.string : strip;

        auto bnds = value.strip.split(",");
        assert(bnds.length == 4);
        min_x = to!double(bnds[0]);
        max_x = to!double(bnds[1]);
        min_y = to!double(bnds[2]);
        max_y = to!double(bnds[3]);
    }

    unittest
    {
        assert(Bounds("0.1,0.2,0.3,0.4") == Bounds(0.1, 0.2, 0.3, 0.4));
        assert(Bounds("0.1,0.2,0.3,0.4\n") == Bounds(0.1, 0.2, 0.3, 0.4));
    }

}

/// Return the height of the given bounds 
double height(Bounds bounds)
{
    return bounds.max_y - bounds.min_y;
}

unittest
{
    assert(Bounds(0, 1.5, 1, 5).height == 4);
}

/// Return the width of the given bounds 
double width(Bounds bounds)
{
    return bounds.max_x - bounds.min_x;
}

unittest
{
    assert(Bounds(0, 1.5, 1, 5).width == 1.5);
}

/// Is the point within the Bounds
bool withinBounds(Bounds bounds, Point point)
{
    return (point.x <= bounds.max_x && point.x >= bounds.min_x
        && point.y <= bounds.max_y && point.y >= bounds.min_y);
}

unittest
{
    assert(Bounds(0, 1, 0, 1).withinBounds(Point(1, 0)));
    assert(Bounds(0, 1, 0, 1).withinBounds(Point(0, 1)));
    assert(!Bounds(0, 1, 0, 1).withinBounds(Point(0, 1.1)));
    assert(!Bounds(0, 1, 0, 1).withinBounds(Point(-0.1, 1)));
    assert(!Bounds(0, 1, 0, 1).withinBounds(Point(1.1, 0.5)));
    assert(!Bounds(0, 1, 0, 1).withinBounds(Point(0.1, -0.1)));
}

/// Can we construct valid bounds given these points
bool validBounds(Point[] points)
{
    if (points.length < 2)
        return false;
    bool validx = false;
    bool validy = false;
    immutable x = points[0].x;
    immutable y = points[0].y;
    foreach (point; points[1 .. $])
    {
        if (point.x != x)
            validx = true;
        if (point.y != y)
            validy = true;
        if (validx && validy)
            return true;
    }
    return false;
}

unittest
{
    assert(validBounds([Point(0, 1), Point(1, 0)]));
    assert(!validBounds([Point(0, 1)]));
    assert(!validBounds([Point(0, 1), Point(0, 0)]));
    assert(!validBounds([Point(0, 1), Point(1, 1)]));
}

/// Return minimal bounds size containing those points
Bounds minimalBounds(Point[] points)
{
    if (points.length == 0)
        return Bounds(-1, 1, -1, 1);
    double min_x = points[0].x;
    double max_x = points[0].x;
    double min_y = points[0].y;
    double max_y = points[0].y;
    if (points.length > 1)
    {
        foreach (point; points[1 .. $])
        {
            if (point.x < min_x)
                min_x = point.x;
            else if (point.x > max_x)
                max_x = point.x;
            if (point.y < min_y)
                min_y = point.y;
            else if (point.y > max_y)
                max_y = point.y;
        }
    }
    if (min_x == max_x)
    {
        min_x = min_x - 0.5;
        max_x = max_x + 0.5;
    }
    if (min_y == max_y)
    {
        min_y = min_y - 0.5;
        max_y = max_y + 0.5;
    }
    return Bounds(min_x, max_x, min_y, max_y);
}

unittest
{
    assert(minimalBounds([]) == Bounds(-1, 1, -1, 1));
    assert(minimalBounds([Point(0, 0)]) == Bounds(-0.5, 0.5, -0.5, 0.5));
    assert(minimalBounds([Point(0, 0), Point(0, 0)]) == Bounds(-0.5, 0.5, -0.5, 0.5));
    assert(minimalBounds([Point(0.1, 0), Point(0, 0.2)]) == Bounds(0, 0.1, 0, 0.2));
}

/// Returns adjust bounds based on given bounds to include point
Bounds adjustedBounds(Bounds bounds, Point point)
{
    import std.algorithm : min, max;

    if (bounds.min_x > point.x)
    {
        bounds.min_x = min(bounds.min_x - 0.1 * bounds.width, point.x);
    }
    else if (bounds.max_x < point.x)
    {
        bounds.max_x = max(bounds.max_x + 0.1 * bounds.width, point.x);
    }
    if (bounds.min_y > point.y)
    {
        bounds.min_y = min(bounds.min_y - 0.1 * bounds.height, point.y);
    }
    else if (bounds.max_y < point.y)
    {
        bounds.max_y = max(bounds.max_y + 0.1 * bounds.height, point.y);
    }
    return bounds;
}

unittest
{
    assert(adjustedBounds(Bounds(0, 1, 0, 1), Point(0, 1.01)) == Bounds(0, 1, 0, 1.1));
    assert(adjustedBounds(Bounds(0, 1, 0, 1), Point(0, 1.5)) == Bounds(0, 1, 0, 1.5));
    assert(adjustedBounds(Bounds(0, 1, 0, 1), Point(-1, 1.01)) == Bounds(-1, 1, 0,
        1.1));
    assert(adjustedBounds(Bounds(0, 1, 0, 1), Point(1.2, -0.01)) == Bounds(0, 1.2,
        -0.1, 1));
}

/// Bounds that can adapt to new points being passed
struct AdaptiveBounds
{
    /*
Notes: the main problem with adaptive bounds is the beginning, where we need to
make sure we have enough points to form valid bounds (i.e. with width and height
> 0). For example if all points fall on a vertical lines, we have no information
for the width of the plot

Here we take care to always return a valid set of bounds
	 */

    /// Actual bounds being used
    Bounds bounds = Bounds(0, 1, 0, 1);
    alias bounds this;

    /// Constructor taking comma separated x and y limits
    this(string str)
    {
        bounds = Bounds(str);
    }

    /// Constructor taking x and y limits
    this(double my_min_x, double my_max_x, double my_min_y, double my_max_y)
    {
        bounds = Bounds(my_min_x, my_max_x, my_min_y, my_max_y);
    }

    /// Contructor taking an existing Bounds struct
    this(Bounds bnds)
    {
        bounds = bnds;
    }

    /// Adapt bounds to include the new point
    bool adapt(T : Point)(in T point)
    {
        import std.math : isFinite;
        bool adapted = false;
        if (!isFinite(point.x) || !isFinite(point.y))
            return adapted;

        if (!valid)
        {
            adapted = true;
            pointCache ~= point;
            valid = validBounds(pointCache);
            bounds = minimalBounds(pointCache);
            if (valid)
                pointCache.length = 0;
        }
        else
        {
            if (!bounds.withinBounds(point))
            {
                bounds = bounds.adjustedBounds(point);
                adapted = true;
            }
        }
        return adapted;
    }

    /// Adapt bounds to include the given bounds 
    bool adapt(T : AdaptiveBounds)(in T bounds)
    {
        bool adapted = false;
        if (bounds.valid)
        {
            immutable bool adaptMin = adapt(Point(bounds.min_x, bounds.min_y));
            immutable bool adaptMax = adapt(Point(bounds.max_x, bounds.max_y));
            adapted = (adaptMin || adaptMax);
        }
        else
        {
            adapted = adapt(bounds.pointCache);
        }
        return adapted;
    }

    import std.range : isInputRange;

    /// Adapt bounds to include the new points
    bool adapt(T)(in T points)
    {
        import std.range : save;
        bool adapted = false;
        foreach (point; points.save)
        {
            immutable a = adapt(point);
            if (a)
                adapted = true;
        }
        return adapted;
    }

private:
    Point[] pointCache;
    bool valid = false;
}

unittest
{
    assert(AdaptiveBounds("0.1,0.2,0.3,0.4") == Bounds(0.1, 0.2, 0.3, 0.4));
    // Test adapt
    AdaptiveBounds bounds;
    assert(bounds.width > 0);
    assert(bounds.height > 0);
    auto pnt = Point(5, 2);
    assert(bounds.adapt(pnt));
    assert(bounds.width > 0);
    assert(bounds.height > 0);
    assert(bounds.withinBounds(pnt));
    assert(!bounds.valid);
    pnt = Point(3, 2);
    assert(bounds.adapt(pnt));
    assert(bounds.width >= 2);
    assert(bounds.height > 0);
    assert(bounds.withinBounds(pnt));
    assert(!bounds.valid);
    pnt = Point(3, 5);
    assert(bounds.adapt(pnt));
    assert(bounds.width >= 2);
    assert(bounds.height >= 3);
    assert(bounds.withinBounds(pnt));
    assert(bounds.valid);
    pnt = Point(4, 4);
    assert(!bounds.adapt(pnt));


    assert(!bounds.adapt(Point(double.init, 1.0)));
    assert(!bounds.adapt(Point(-1.0,double.init)));
    assert(!bounds.adapt(Point(double.init, double.init)));

    import std.math;
    assert(!bounds.adapt(Point(log(0.0), 1.0)));
    assert(!bounds.adapt(Point(-1.0,log(0.0))));
    assert(!bounds.adapt(Point(log(0.0), log(0.0))));
}

unittest
{
    AdaptiveBounds bounds;
    assert(!bounds.valid);
    AdaptiveBounds bounds2;
    assert(!bounds.adapt(bounds2));

    bounds2.adapt(Point(1.1, 1.2));
    bounds.adapt(bounds2);
    assert(!bounds.valid);
    AdaptiveBounds bounds3;
    bounds3.adapt(Point(1.2, 1.3));
    bounds.adapt(bounds3);
    assert(bounds.valid);

    AdaptiveBounds bounds4;
    assert(!bounds4.valid);
    AdaptiveBounds bounds5;
    bounds5.adapt(Point(1.1, 1.2));
    bounds5.adapt(Point(1.3, 1.3));
    assert(bounds5.valid);
    bounds4.adapt(bounds5);
    assert(bounds4.valid);
}

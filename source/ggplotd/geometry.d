/// Helper functions for working with geometrical shapes
module ggplotd.geometry;

version( unittest )
{
    import dunit.toolkit;
}

/// Vertex in 3D space
struct Vertex3D
{
    /// x value
    double x;
    /// y value
    double y;
    /// z value
    double z;

    /// Copy constructor
    this( in Vertex3D v )
    {
        x = v.x; y = v.y; z = v.z;
    }

    /// Constructor taking x, y and z value
    this( in double _x, in double _y, in double _z )
    {
        x = _x; y = _y; z = _z;
    }

    /// Vertex substraction or addition
    Vertex3D opBinary(string s)( in Vertex3D v2 ) const if (s == "-" || s == "+" )
    {
        import std.format : format;
        mixin( format("return Vertex3D( x %s v2.x, y %s v2.y, z %s v2.z );",s,s,s) );
    }
}
unittest
{
    immutable v1 = Vertex3D(1,2,3);
    immutable v2 = Vertex3D(3,2,1);
    auto v =  v1-v2;
    assertEqual( v, Vertex3D(-2,0,2) );
    v =  v1+v2;
    assertEqual( v, Vertex3D(4,4,4) );
}

private Vertex3D crossProduct( in Vertex3D v1, in Vertex3D v2 )
{
    return Vertex3D( v1.y*v2.z-v1.z*v2.y, 
        v1.z*v2.x-v1.x*v2.z, 
        v1.x*v2.y-v1.y*v2.x );
}

unittest
{
    auto v = Vertex3D(1,2,3).crossProduct( Vertex3D( 3,2,1 ) );
    assertEqual( v, Vertex3D(-4,8,-4) );
}

/// Calculate gradientVector based on a Triangle. The vertices of the triangle are assumed to be sorted by height.
auto gradientVector( T )( in T triangle )
{
    import std.math : pow;
    assert( triangle[0].z <= triangle[1].z && triangle[1].z <= triangle[2].z,
        "gradientVector expects the triangle vertices to be sorted by height" );
    auto gVector = [ Vertex3D(triangle[0]), Vertex3D(triangle[2]) ];

    if (triangle[0].z == triangle[2].z) {
        return gVector;
    }

    auto e1 = triangle[2]-triangle[0];
    auto e2 = triangle[1]-triangle[0];
    auto normal = e1.crossProduct( e2 );

    Vertex3D v;
    if (normal.x == 0)
    {
        v = Vertex3D( normal.x/normal.y, 1, 
            -(pow(normal.y,2)+pow(normal.x,2))/(normal.y*normal.z)
            );
    } else 
    {
        v = Vertex3D( 1, normal.y/normal.x, 
            -(pow(normal.y,2)+pow(normal.x,2))/(normal.x*normal.z)
            );
    }

    immutable scalar = (gVector[1].z-gVector[0].z)/v.z;

    gVector[1].x = gVector[0].x + scalar*v.x;
    gVector[1].y = gVector[0].y + scalar*v.y;
    gVector[1].z = gVector[0].z + scalar*v.z;

    return gVector; 
}

unittest
{
    auto v = gradientVector( [ Vertex3D( 0, 0, 1 ),
        Vertex3D( 0, 1, 1 ),
        Vertex3D( 1, 1, 1 )] );
    assertEqual( v[0].z, v[1].z );

    v = gradientVector( [ Vertex3D( 0, 0, 0 ),
        Vertex3D( 0, 1, 0.5 ),
        Vertex3D( 1, 1, 1 )] );
    assertEqual( v, [Vertex3D(0, 0, 0), Vertex3D(1, 1, 1)] );

    v = gradientVector( [ Vertex3D( 0, 0, 0 ),
        Vertex3D( 0, 1, 0.1 ),
        Vertex3D( 1, 1, 1 )] );
    assertEqual( v[0], Vertex3D(0, 0, 0) );
    assertApprox( v[1].x, 1.09756, 1e-5 );
    assertApprox( v[1].y, 0.121951, 1e-5 );
    assertApprox( v[1].z, 1.0 );
}


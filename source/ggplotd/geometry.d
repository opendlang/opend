/// Helper functions for working with geometrical shapes
module ggplotd.geometry;

version( unittest )
{
    import dunit.toolkit;
}

struct Vertex3D
{
    double x;
    double y;
    double z;

    this( in Vertex3D v )
    {
        x = v.x; y = v.y; z = v.z;
    }

    this( in double _x, in double _y, in double _z )
    {
        x = _x; y = _y; z = _z;
    }

    Vertex3D opBinary(string s)( in Vertex3D v2 ) if (s == "-" || s == "+" )
    {
        mixin( "return Vertex3D( x " ~ s ~ " v2.x, y " ~ s ~ 
            " v2.y, z " ~ s ~ " v2.z );");
    }
}
unittest
{
    auto v1 = Vertex3D(1,2,3);
    auto v2 = Vertex3D(3,2,1);
    auto v =  v1-v2;
    assertEqual( v, Vertex3D(-2,0,2) );
    v =  v1+v2;
    assertEqual( v, Vertex3D(4,4,4) );
}

Vertex3D crossProduct( in Vertex3D v1, in Vertex3D v2 )
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
    assert( triangle[0].z <= triangle[1].z && triangle[1].z <= triangle[2].z,
        "gradientVector expects the triangle vertices to be sorted by height" );
    auto gVector = [ Vertex3D(triangle[0]), Vertex3D(triangle[2]) ];

    if (triangle[0].z == triangle[2].z) {
        return gVector;
    }

    return gVector; 
}

unittest
{
    import std.stdio;
    auto v = gradientVector( [ Vertex3D( 0, 0, 1 ),
        Vertex3D( 0, 1, 1 ),
        Vertex3D( 1, 1, 1 )] );
    assertEqual( v[0].z, v[1].z );

    v = gradientVector( [ Vertex3D( 0, 0, 0 ),
        Vertex3D( 0, 1, 0.5 ),
        Vertex3D( 1, 1, 1 )] );
    v.writeln;

    v = gradientVector( [ Vertex3D( 0, 0, 0 ),
        Vertex3D( 0, 1, 0.1 ),
        Vertex3D( 1, 1, 1 )] );
    v.writeln;
 
}


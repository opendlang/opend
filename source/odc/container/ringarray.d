module odc.container.ringarray;

enum string defaultoverflow="assert(false,
    q{how a ring array overflows should probaly be userdefined, consider ring!(T,true,64,donothing)});";
struct ring(T,bool fifo=true,size_t size=64,
    string overflow=defaultoverflow){
  T[size] data;
  ringint head;
  ringint tail;
  T front(){return data[head];}
  void popFront(){head++;}
  bool empty(){return head==tail;}
  T get(){
    T temp = front;
    popFront;
    return temp;
  }
  alias get this;
  void opOpAssign(string op)(T a){
    static if(fifo){
      data[tail]=a;
      tail++;
      if(tail == head){mixin(overflow);}
    } else {
      head--;
      if(tail== head){mixin(overflow);}
      data[head]=a;
    }
  }
  
  
  
  struct ringint{
    static if(size<250){ubyte data;}
           else {       size_t data;}
    auto get(){
      assert(data < size,"ring int should always be inbounds, how did you manage that?");
      return data;
    }
    void opUnary(string op:"++")(){
      if(data==size-1){data=0;}
      else data++;
    }
    void opUnary(string op:"--")(){
      if(data==0){data=size-1;}
      else data--;
    }
    void opAssign(typeof(data) a){
      a= a%size;
      data=a;
    }
    alias get this;
  }
}
enum string donothing="";
enum string drophalf="tail=tail+size;";
enum string drophead="head++;";
enum string droptail="tail--;";

unittest{
  ring!(int) foo;
  foo+=1;
  assert(foo.front==1);
  foo+=2;
  foo+=3;
  foo.popFront;
  assert(foo.front==2);
  foo+=4;
  foo.popFront;
  foo.popFront;
  assert(foo.front==4);
  foreach(bar;foo){}
}

unittest{
  ring!int foo;
  foo+=1;
  foo+=2;
  foo+=3;
  assert(foo==1);
  assert(foo==2);
  assert(foo==3);
}
unittest{
  ring!(int,false) foo;
  foo+=1;
  foo+=2;
  foo+=3;
  //import std.stdio;
  //foo.writeln;
  assert(foo==3);
  assert(foo==2);
  assert(foo==1);
}
unittest{
  struct inf{
    int i;
    int front(){return i;}
    void popFront(){i++;}
    enum empty=false;
    int get(){
      int t=front;
      popFront;
      return t;
    }
    alias get this;
  }
  inf input;
  inf output;
  
  ring!int foo;
  foo+=input;
  foo+=input;
  foo+=input;
  foreach(i;1..1000){
    assert(foo==output);
    foo+=input;
  }
  
}

unittest{
  struct inf{
    int i;
    int front(){return i;}
    void popFront(){i++;}
    enum empty=false;
    int get(){
      int t=front;
      popFront;
      return t;
    }
    alias get this;
  }
  inf input;
  ring!int foo;
  import std.stdio;
  foreach(i;1..60){foo+=input;}
  while(!foo.empty){
    if(foo.front%2==0){foo+=input;}
    else{foo.front.writeln;}
    foo.popFront;
  }
}


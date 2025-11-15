/*
core:
	front (techincally optional now)
	popFront (popFront when phoboes compadiblity matters)
	empty

reference:
	data* (with opIndex(key))
	key
	keyback

length

bidirectional
	back
	popBack
	keyBack

"slicable":
	drop
	dropBack
*/
auto counter(int i/*exclusive*/){//TODO: swizzle args TODO: generic types TODO:step
	struct Counter{
		int key;
		int keyBack;//inclusive
		auto front()=>key;
		void popFront(){key++;}
		bool empty()=>key>keyBack;
		auto back()=>keyBack;
		auto popBack(){keyBack--;}
		auto drop(int i){key+=i;}
		auto dropBack(int i){keyBack-=i;}
		int length()=>keyBack-key+1;
	}
	return Counter(0,i-1);
}
auto map(alias F,R)(R r){
	struct Map{
		R r;
		auto front()=>F(r.front);
		void popFront(){r.popFront;}
		bool empty()=>r.empty;
		auto data()()=>r.data;
		auto key()()=>r.key;
		auto keyBack()()=>r.keyBack;
		auto length()()=>r.length;
		auto back()()=>F(r.back);
		void popBack()(){r.popBack;}
		void drop()(int i){r.drop(i);}
		void dropBack()(int i){r.dropBack(i);}
	}
	return Map(r);
}
unittest{
	import std;
	//counter(5).map!(a=>a*2).writeln;
}
void summery(R)(R r){//temp?
	import std;
	writeln("summery of ",R.stringof);
	static if(is(typeof(r.front.writeln))){
		writeln("front:",r.front);
	} else {
		writeln("front: no compile");
	}
	static if(is(typeof(r.popFront))){
		writeln("popFront: compiles");
	} else {
		writeln("popFront: no compile");
	}
	static if(is(typeof(r.empty.writeln))){
		writeln("empty:",r.empty);
	} else {
		writeln("empty: no compile");
	}
	static if(is(typeof(*r.data))){
		writeln("data:",typeof(*r.data));
	} else {
		writeln("data: no compile");
	}
	static if(is(typeof(r.key.writeln))){
		writeln("key:",r.key);
	} else {
		writeln("key: no compile");
	}
	static if(is(typeof(r.keyBack.writeln))){
		writeln("keyBack:",r.keyBack);
	} else {
		writeln("keyBack: no compile");
	}
	static if(is(typeof(r.length.writeln))){
		writeln("length:",r.length);
	} else {
		writeln("length: no compile");
	}
	static if(is(typeof(r.back.writeln))){
		writeln("back:",r.back);
	} else {
		writeln("back: no compile");
	}
	static if(is(typeof(r.popBack))){
		writeln("popBack: compiles");
	} else {
		writeln("popBack: no compile");
	}
	static if(is(typeof(r.drop(1)))){
		writeln("drop: compiles");
	} else {
		writeln("drop: no compile");
	}
	static if(is(typeof(r.dropBack(1)))){
		writeln("dropBack: compiles");
	} else {
		writeln("dropBack: no compile");
	}
	static if(is(typeof(r.writeln))){
		writeln("writeln:",r);
	} else {
		writeln("writeln: no compile");
	}
}
unittest{
	//counter(5).map!(a=>a*2).summery;
	//[1,2,3].summery;
	//13.37.summery;
}
auto slide(R)(R r){
	struct Slide{//TODO: more functions
		R front_;
		auto front()=>front_;//need to dup, prevents refness
		void popFront(){front_.popFront;}
		bool empty()=>front_.empty;
	}
	return Slide(r);
}
unittest{
	//counter(5).slide.summery;
}
auto find(alias F,R)(R r){
	while( ! r.empty && ! F(r.front)){
		r.popFront;
	}
	return r;
}
unittest{
	//counter(5).find!(a=>a==3).summery;
}
auto findnext(alias F,R)(R r){
	r.popFront;
	return r.find!F;
}
auto filter(alias F,R)(R r){
	struct Filter{
		R r;
		auto ref front()=>r.front;
		void popFront(){r=r.findnext!F;}
		bool empty()=>r.empty;
	}
	return Filter(r.find!F);
}
unittest{
	//counter(10).filter!(a=>a%3).summery;
}
auto acc(alias F,R,A...)(R r,A args){//TODO: impliment empty and 1 length ranges TODO: imilment tuple hacks TODO: honestly do allot
	alias E=typeof(F(r.front,args));
	struct Acc{
		R r;
		E store;
		bool empty=false;
		auto front()=>store;
		void popFront(){
			if(r.empty){empty=true; return;}
			store=F(r.front,store);
			r.popFront;
		}
		
	}
	return Acc(r,F(r.front,args));
}
unittest{
	//counter(5).acc!((a,int b=0)=>a+b).summery;
}
auto last(R)(R r){//nullable?
	auto e=r.front;
	while( ! r.empty){
		e=r.front;
		r.popFront;
	}
	return e;
}
unittest{
	//counter(5).last.summery;
}
auto reduce(alias F,R)(R r)=>r.acc!F.last;
unittest{
	//counter(5).reduce!((a,int b=0)=>a+b).summery;
}

auto backwards(R)(R r){//CONSIDER: should backwards change indexs or just pass thru because easier
	struct Backwards{
		R r;
		auto ref front()=>r.back;
		void popFront(){r.popBack;}
		bool empty()=>r.empty;
		auto ref key()()=>r.keyBack;
		auto ref keyBack()()=>r.key;
		auto ref back()=>r.front;
		void popBack(){r.popFront;}
		auto length()()=>r.length;
		auto data()()=>r.data;
		void drop(int i){r.dropBack(i);}
		void dropBack(int i){r.drop(i);}
		auto backwards()=>r;
	}
	return Backwards(r);
}
unittest{
	//counter(5).backwards.find!(a=>a==2).backwards.summery;
}
auto takeuntil(alias F,R)(R r){
	struct Until{
		R r;
		auto ref front()=>r.front;
		void popFront()=>r.popFront;
		bool empty()=>r.empty || F(r);
		auto data()()=>r.data;
		auto key()()=>r.key;
		//CONSIDER: is it possible to impliment a smarter drop?
	}
	return Until(r);
}
auto canfind(alias F,R)(R r)=> ! r.find!F.empty;
auto cantfind(alias F,R)(R r)=>r.find!F.empty;
//mixin template autodecoding(){
//	auto front(T)(T[] a)=>a[0];
//	void popFront(T)(ref T[] a){a=a[1..$];}
//	bool empty(T)(T[] a)=>a.length==0;
//}
auto range(T)(T[] a){
	struct Range{
		T[] a;
		ref front()=>a[0];
		void popFront(){a=a[1..$];}
		bool empty()=>a.length==0;
		//TODO:
	}
	return Range(a);
}

unittest{
	//counter(5).canfind!(a=>a==10).summery;
	//counter(10).slide.find!(a=>a.length==3).front.summery;
	//["front","popFront"].range.cantfind!(a=>a=="empty").summery;
	//static if(["empty"].range.cantfind!(a=>a=="empty")){
	//}
	//enum disable=["empty"];
	//static if(disable.range.cantfind!(a=>a=="empty")){
	//}
	//struct foo{
	//	static if(["empty"].cantfindstrings!(a=>a)("empty")){
	//	}
	//}
}
/*RANT:
https://github.com/dlang/dmd/issues/20683
even when I think im in well tred terrortory I still find compiler bugs
cant inline the logic of rangemixin til its gone
*/
bool cantfind(T)(T[] a,T e)=>a.range.cantfind!(a=>a==e);

auto rangemixin(string __mixin,string[] disable=[],R,Args...)(R r,Args args){
	struct Mixed{
		R r;
		mixin(__mixin);
		static if(disable.cantfind("front")){
			auto ref front()=>r.front;
		}
		static if(disable.cantfind("popFront")){
			void popFront(){r.popFront;}
		}
		static if(disable.cantfind("empty")){
			bool empty()=>r.empty;
		}
		//TODO:
	}
	return Mixed(r,args);
}
auto take(R)(R r,int i)=>r
	.rangemixin!("int i; void popFront(){i--;r.popFront;}",["popFront"])(i)
	.takeuntil!(r=>r.i<=0);
unittest{
	//counter(1000).take(5).summery;
}
auto chunks(R)(R r,int i){
	struct Chunks{
		R r;
		int i;
		auto front()=>r.take(i);
		void popFront(){r.drop(i);}
		bool empty()=>r.empty;
		//TODO:
	}
	return Chunks(r,i);
}
unittest{
	//counter(10).chunks(4).summery;
}
auto cycle(R)(R r){
	struct Cycle{
		R r;
		R rbackup;
		auto ref front()=>r.front;
		void popFront(){
			if(r.empty){
				r=rbackup;
			} else {
				r.popFront;
		}}
		enum empty=false;
		//TODO:
	}
	return Cycle(r,r);
}
unittest{
	//counter(3).cycle.take(17).summery;
}
auto chain(R1,R2)(R1 r1,R2 r2){
	struct Chain{
		R1 r1;
		R2 r2;
		auto ref front()=>r1.empty?r2.front:r1.front;
		void popFront(){
			if(r1.empty){
				r2.popFront;
			} else {
				r1.popFront;
		}}
		bool empty()=>r1.empty && r2.empty;
	}
	return Chain(r1,r2);
}
unittest{
	//chain(counter(3),counter(3).map!(a=>a*2)).summery;
}
auto stride(R)(R r,int i)=>r.chunks(i).map!(a=>a.front);
unittest{
	//counter(15).stride(4).summery;
}

/**
 * Container mixins
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module containers.internal.mixins;

mixin template AllocatorState(Allocator)
{
	static if (stateSize!Allocator == 0)
		alias allocator = Allocator.instance;
	else
		Allocator allocator;
}

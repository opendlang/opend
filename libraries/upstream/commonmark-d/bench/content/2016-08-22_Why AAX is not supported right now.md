# Why don't you support Pro Tools?


**(UPDATE: since January 18th 2018, the AAX format is supported)**

As of 2016, the AAX plugin format is not supported in Auburn Sounds plugins. Therefore, you can't use them in Pro Tools without a wrapper. The reasons are simple: time and cost.


## Manpower

With Panagement launch, Audio Unit support, and the race towards a 1.1 release that would fix most remaining bugs, there is simply no time to support another plugin format right now. Especially with Auburn Sounds being one person. I'm guessing adding AAX support would be three man-months of work, which is half a plugin.

Why doesn't Auburn Sounds rely on a ready-made framework that would have AAX built-in then? There are pros and cons of course. The problem with this strategy happens when a difficult bug occurs. You realize you rely on some large amount of code you don't really understand. Things do not look so good at this point.

Making an own framework allows to understand completely what's going on. In our case, this enables the particular look of the plugins and small size of the binaries. This is a reward in differentiation and control, one that many audio companies have seeked and paid for.


## N plugins x M formats

When you have only two products people can buy, it isn't economically sound to add new formats before extending the product line. It makes more sense to create a new sellable artifact that will most probably add 50% to sales, than to add a new format that would maybe add 30% top.

This all compounds to make implementing AAX a costly choice to make for this particular software shop.

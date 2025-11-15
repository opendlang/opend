/++
	The OpenD Collection aims to provide a stable entry point to common functionality as part of a standard library of code.


	$(H2 Using it)

	`import` the modules you need as you need them. `import odc;` may bring in some functionality, but it will not be comprehensive.

	$(H2 Organization)

	When applicable, interfaces, definitions, etc. belong in one module, implementations belong in another. Then a third module - with the simplest name - imports both.

	In some cases, the implementation can be hidden behind a template function instead. The goal is to be able to use the interface without the prepackaged implementation, so it can be swapped out.

	Alternatively, depending on the situation, you might take delegates, helper classes, or *rarely*, alias template params, for customization.

	Virtual functions meant to be overridden ought to declare a struct to hold their params, so make extending them with others easier in the future.

	$(H2 Developer Notes)

	`odc` modules should focus primarily on providing stable interfaces. The implementation can (and likely should) be delegated to other modules. These modules can come from throughout the ecosystem; the OpenD distribution can include them as needed.

	odc modules can import one another, but try to be mindful of what is actually necessary. Avoid doing ctfe in commonly imported modules to keep compile time low.

	$(H2 Relationship to core, std and arsd)

	OpenD comes with three other key packages: `core`, which is druntime's namespace, `std`, which is the inherited standard library from upstream D, and `arsd`, which is the extended utility package contributed by OpenD's main corporate sponsor.

	`odc` can use code from any of these packages, but odc should aim to provide its own stabilized interface to them, ideally (but not necessarily), one that can also be used with other implementation.

	`core` is not necessarily stable. You are free to use it directly and it tends not to change often, but it is nevertheless tied to compiler internals and thus may change across updates. If their is equivalent functionality in `core` and `odc`, the `odc` version should have more compatibility guarantees across updates. Note that `core` modules are $(I not) allowed to import `odc` modules under current policies.

	`std` tries to maintain compatibility with upstream D, for ease of porting existing codebases. In practice, it has barely changed for years, and I don't expect much will, so it should be safe to use directly and we will likely make incremental improvements on it, but `odc` versions of `std`'s functionality is likely to have more improved interfaces.

	`arsd`is fully available directly from any OpenD application at any time, and has a generally stable interface while still being actively developed, but its implementations are not necessarily swappable and interfaces not necessarily compatible with other third party packages the way `odc` is.

	All other packages provided with the OpenD distribution are hopefully useful, but have no guarantee of long term support and compatibility with anything else.
+/
module odc;

pragma(msg, "import specific odc packages instead");

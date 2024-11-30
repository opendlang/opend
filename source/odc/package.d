/++
	The OpenD Collection aims to provide a stable entry point to common functionality as part of a standard library of code.


	$(H2 Using it)

	`import` the modules you need as you need them. `import odc;` may bring in some functionality, but it will not be comprehensive.

	$(H2 Developer Notes)

	`odc` modules should focus primarily on providing stable interfaces. The implementation can (and likely should) be delegated to other modules. These modules can come from throughout the ecosystem; the OpenD distribution can include them as needed.

	odc modules can import one another, but try to be mindful of what is actually necessary. Avoid doing ctfe in commonly imported modules to keep compile time low.
+/
module odc;

pragma(msg, "import specific odc packages instead");

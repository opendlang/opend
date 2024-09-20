The libraries are formed by git subtree merging <https://docs.github.com/en/get-started/using-git/about-git-subtree-merges> upstream things and modifying as needed here.

To pull from upstream, to a pull and rebase of our hacks here using the subtree thing.

e.g.: `git pull -s subtree arsd master` note the `arsd` there is the name of the repo.

Then the libraries are "built" using a special script here that extracts the necessary files to the actual usage path.


		Still desired:
		// openssl
		// generally most the deimos

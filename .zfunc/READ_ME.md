See directions on how to add global functions to zsh below via the url or
pasted stack overflow link:

**Link to Answer**
https://unix.stackexchange.com/questions/33255/how-to-define-and-load-your-own-shell-function-in-zsh

**Pasted Answer:**
In zsh, the function search path ($fpath) defines a set of directories, which contain files that can be marked to be loaded automatically when the function they contain is needed for the first time.

Zsh has two modes of autoloading files: Zsh's native way and another mode that resembles ksh's autoloading. The latter is active if the KSH_AUTOLOAD option is set. Zsh's native mode is the default and I will not discuss the other way here (see "man zshmisc" and "man zshoptions" for details about ksh-style autoloading).

Okay. Say you got a directory `~/.zfunc' and you want it to be part of the function search path, you do this:

fpath=( ~/.zfunc "${fpath[@]}" )
That adds your private directory to the front of the search path. That is important if you want to override functions from zsh's installation with your own (like, when you want to use an updated completion function such as `_git' from zsh's CVS repository with an older installed version of the shell).

It is also worth noting, that the directories from `$fpath' are not searched recursively. If you want your private directory to be searched recursively, you will have to take care of that yourself, like this (the following snippet requires the `EXTENDED_GLOB' option to be set):

fpath=(
    ~/.zfuncs
    ~/.zfuncs/**/*~*/(CVS)#(/N)
    "${fpath[@]}"
)
It may look cryptic to the untrained eye, but it really just adds all directories below `~/.zfunc' to `$fpath', while ignoring directories called "CVS" (which is useful, if you're planning to checkout a whole function tree from zsh's CVS into your private search path).

Let's assume you got a file `~/.zfunc/hello' that contains the following line:

printf 'Hello world.\n'
All you need to do now is mark the function to be automatically loaded upon its first reference:

autoload -Uz hello
"What is the -Uz about?", you ask? Well, that's just a set of options that will cause `autoload' to do the right thing, no matter what options are being set otherwise. The `U' disables alias expansion while the function is being loaded and the `z' forces zsh-style autoloading even if `KSH_AUTOLOAD' is set for whatever reason.

After that has been taken care of, you can use your new `hello' function:

zsh% hello
Hello world.
A word about sourcing these files: That's just wrong. If you'd source that `~/.zfunc/hello' file, it would just print "Hello world." once. Nothing more. No function will be defined. And besides, the idea is to only load the function's code when it is required. After the `autoload' call the function's definition is not read. The function is just marked to be autoloaded later as needed.

And finally, a note about $FPATH and $fpath: Zsh maintains those as linked parameters. The lower case parameter is an array. The upper case version is a string scalar, that contains the entries from the linked array joined by colons in between the entries. This is done, because handling a list of scalars is way more natural using arrays, while also maintaining backwards compatibility for code that uses the scalar parameter. If you choose to use $FPATH (the scalar one), you need to be careful:

FPATH=~/.zfunc:$FPATH
will work, while the following will not:

FPATH="~/.zfunc:$FPATH"
The reason is that tilde expansion is not performed within double quotes. This is likely the source of your problems. If echo $FPATH prints a tilde and not an expanded path then it will not work. To be safe, I'd use $HOME instead of a tilde like this:

FPATH="$HOME/.zfunc:$FPATH"
That being said, I'd much rather use the array parameter like I did at the top of this explanation.

You also shouldn't export the $FPATH parameter. It is only needed by the current shell process and not by any of its children.

Update
Regarding the contents of files in `$fpath':

With zsh-style autoloading, the content of a file is the body of the function it defines. Thus a file named "hello" containing a line echo "Hello world." completely defines a function called "hello". You're free to put hello () { ... } around the code, but that would be superfluous.

The claim that one file may only contain one function is not entirely correct, though.

Especially if you look at some functions from the function based completion system (compsys) you'll quickly realise that that is a misconception. You are free to define additional functions in a function file. You are also free to do any sort of initialisation, that you may need to do the first time the function is called. However, when you do you will always define a function that is named like the file in the file and call that function at the end of the file, so it gets run the first time the function is referenced.

If - with sub-functions - you didn't define a function named like the file within the file, you'd end up with that function having function definitions in it (namely those of the sub-functions in the file). You would effectively be defining all your sub-functions every time you call the function that is named like the file. Normally, that is not what you want, so you'd re-define a function, that's named like the file within the file.

I'll include a short skeleton, that will give you an idea of how that works:

# Let's again assume that these are the contents of a file called "hello".

# You may run arbitrary code in here, that will run the first time the
# function is referenced. Commonly, that is initialisation code. For example
# the `_tmux' completion function does exactly that.
echo initialising...

# You may also define additional functions in here. Note, that these
# functions are visible in global scope, so it is paramount to take
# care when you're naming these so you do not shadow existing commands or
# redefine existing functions.
hello_helper_one () {
    printf 'Hello'
}

hello_helper_two () {
    printf 'world.'
}

# Now you should redefine the "hello" function (which currently contains
# all the code from the file) to something that covers its actual
# functionality. After that, the two helper functions along with the core
# function will be defined and visible in global scope.
hello () {
    printf '%s %s\n' "$(hello_helper_one)" "$(hello_helper_two)"
}

# Finally run the redefined function with the same arguments as the current
# run. If this is left out, the functionality implemented by the newly
# defined "hello" function is not executed upon its first call. So:
hello "$@"
If you'd run this silly example, the first run would look like this:

zsh% hello
initialising...
Hello world.
And consecutive calls will look like this:

zsh% hello
Hello World.
I hope this clears things up.

(One of the more complex real-world examples that uses all those tricks is the already mentioned `_tmux' function from zsh's function based completion system.)

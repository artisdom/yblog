---
kind:           article
published:      2016-05-06
image: /content/Scratch/img/blog/Haskell-Tutorials--a-tutorial/main.png
title: Haskell Tutorials, a tutorial
author: Yann Esposito
authoruri: yannesposito.com
tags: programming, tutorial, haskell, documentation
theme: scientific
---
blogimage("main.png","Main image")

<div class="intro">

%tldr Haskell is awesome! But it is not perfect yet.
As a community we can do a better at documenting our libraries.
This document provide some hints to make it happens.

</div>


This is a guide on best practices on writing Haskell documentation
for your library.


> Who are you who are so wise in the way of science?

So I am myself largely subject to criticism.
This article isn't intented to be a bible.
More like a tour of what I feel is the most liked
way of documenting. So please, not arsh feeling.

The things I would really dislike people would talk about this article.

- Starting an Holy War about the different Haskell coding style.
  For example, I don't see anything wrong relative to the documentation of using

~~~ haskell
import Prelude hiding ((.))
(.) f g x = g (f x)
~~~

Is this an abomination because you consider it will break
Haskellers habit? Yes.
Does it have something to do with clarity? Yes.
Is it documentation? No.

For absolute Haskell beginner using `(f (g (h x)))`
might seems more readable than `f $ g $ h x` or `f . g . h $ x`.

But this is not about documentation.

## Other communities

While Haskell is great, some other languages have in my humble opinion
a far better habit concerning documentation.
Documentation shouldn't be felt like a punishment.
On the contrary it is a way of proving by example how your work
is great!

I don't want to dive in the details of the other communities
but I was slightly inspired by:

- Elm
- Clojure
- Node.js

In clojure when you create a new project using `lein new my-project`
a directory `doc` is created for you. It contains a file with a link
to this blog post:

- [What to write](https://jacobian.org/writing/what-to-write/)

A great deal is made about *tutorials*.

Because this is generally what most first users of you library will start.
They just want to pass from zero to something in the minimal amount of time
possible.

In Haskell we already have API generated documentation for free.
Hackage and Stackage both do a great job at generating your documentation.


So now the best students in class in my humble opinion:

- [`turtle`](https://www.stackage.org/package/turtle)
- [`lens`](https://www.stackage.org/package/lens)

Both library are not only aweseme for different reasons.
Their documentation contains examples, and a tutorial.
You can go deeper if you need to.

To make them even better.

1. Use `doctest` that way you will be able to *test* your tutorial and fix it
   if your API break or change. You'll be able to check it using travis CI for
   example.
2. One advantage of providing a `MyPackage.Tutorial` file is the ability to use `doctest`.

## Good Ideas

- [`clojuredocs.org`](http://clojuredocs.org)

For each symbol necessiting a documentation.
You don't only have the details and standard documentation.
You'll also get:

- Responsive Design (sometime you want to look at documentation on a mobile)
- Contributed Examples
- Contributed See Also section
- Contributed notes/comments

Clojuredocs is an independant website from the official Clojure website.

Most of the time, if you google the function you search
you end up on clojredocs for wich there are many contributions.

Imagine if we had the same functionalities in hackage/stackage.

Today a lot of information is lost on IRC or mailing list.
I know you could always find the information in the archives
but, as an end-user, it is always better to have a centralized
source of information.

Differences with existing:

- hackage has haddock
- stackage has haddock + per package comment

I believe he would be more efficient to have at least a page
by module and why not a page by *symbol*.
I mean:

- for data type definition with all their class instances
- for functions
- for typeclasses

Why?

- far less informations per page.
- Let's keep the pages we have.
- But let's just also focus more.
  So we could provide details about `foldl` for example.
  And make the design cleaner.
  As a matter of design, think about the 4 of 5 most
  important information someone want to have
  as fast as possible and provide them.
  The rest should be at the bottom, or very small in
  the navigation bar.

- function:
  1. type
  2. Documentation string
  3. Examples
  4. the version / who really care?

## How to help

There are 20k Haskell readers.
If only 1% of them pass 10 minutes adding a bit of
documentation it will certainly change a lot of
things in the percieved documenation quality.

Not too much work:

1. login
2. add/edit some example, comments, see-also section

If you pass only the next 10 minutes in adding a bit of
documentation it will certainly change a lot of things.


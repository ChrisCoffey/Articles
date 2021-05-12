---
title: "Build your very own ban hammer"
date: 2021-05-11T17:07:29-04:00
draft: false
tags: ["web"]
---

In this post, I describe how to implement a ban button in a web application with minimal boilerplate.
This is one of those features that shouldn't be used often, but when you need it, you need it.

The requirements for a useful user ban are simple and straightforward; prevent them from doing anything else on the application.
You can break that down into two parts.
First, prevent them from doing anything else _right now_.
And second, prevent them from doing anything else in the future.
Whatever they've done to get themselves banned typically can't be automatically cleaned up in the same action, so it's not worth adding that to the requirements.

The simplest and easiest way to immediately stop someone from using your application is to expire their session.
In broad strokes, a session is either stored in the browser using cookies/local storage or somewhere on the backend.
The details of how to expire a session vary depending on the application's stack and storage approach used, so I'm not going to try explaining all the permutations.
Thankfully, most stacks make this relatively easy.
Expiring a session is more or less equivalent to logging someone out of the application, which stops them from using it until they log back in.

If expiring the session gets somebody out of the application, the next question is how to prevent them from getting back in?
For that, you'll need to modify your authentication flow to only allow _unblocked_ users into the application.
Again, this varies from application to application, but all you need is a flag on the account indicating that it's been banned.
Once the flag is in place it's trivial to add a check during the OAuth callback, DB lookup, or whatever other auth flow your application uses.

The interesting piece of implementing the ban hammer is whether or not to make banning instant from _your_ perspective.
When I was first thinking about this problem I naturally looked at it from my perspective.
When _I_ click the button, _I_ want the target user to be banned immediately.
Unlike the basic requirements above, this turns out to be more complicated.

Consider for a moment how you would immediately end a session stored entirely in a cookie.
The cookie(s) are passed back and forth on each request and can be written back to by the server, providing a means to clear the data.
But that happens when the user makes their next request, not when you click the ban button.
You may have more control over session data if it's stored on the backend, but changing the frame of reference like this should call to question what value an _immediate_ ban holds.

It turns out that from both the person being banned - and every other user on your platform - there is no _observable_ difference between evicting the user the moment you click the button or on their next request.
Adding a piece of middleware to your webserver's stack after the session is reconstructed but before running any application code - typically at the application-level, like Rails' `before_action` - that resets banned sessions is all you need.
The solution amounts to two additional checks, one during login ensuring the user isn't banned, and one early in the request processing pipeline that resets banned sessions.
Well, I suppose you need a big red ban button as well...

Note that the design changes a bit for a websocket or other direct connection since you need to destroy those the moment the ban is initiated.
In that case, because the socket would have been authenticated at the initial request for a socket, there typically isn't additional mid-stream authentication occurring.
Meaning they'll be able to keep using your sockets unless you explicitly close them as part of the ban.

Hopefully you never need to use your ban button, but at least now you're aware of an easy baseline approach to implementing one!

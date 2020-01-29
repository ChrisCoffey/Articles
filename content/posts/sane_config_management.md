---
title: "Finally, application config management you can live with"
date: 2020-01-18T20:59:44-05:00
draft: false
images:
tags:
  - devops
  - configuration
  - engineering
---

Today I want to talk about the least-exciting part of developing an application, configuration.
All those pesky little details that change across environments, or might change.
You've done the smart thing and factored them out into environment variables, or key-value-pairs in a configuration file, etc...
And now your application's code is clear and concise, and works great when you flip between production and development mode.
However, there's still one unanswered question - where do you actually store all of this configuration?

For the remainder of this article, I'm going to assume a few things about the application we're discussing.
1) It is portable across different machines
2) It connects to the outside world in some manner
3) It is source controlled

In other words, its your typical generic networked application.

In the remainder of this post I'm going to quickly survey the current approaches to storing application config I've encountered.
I'll point out how each of them is broken in some subtle or not-so-subtle way.
Finally, towards the end I'll introduce [Confcrypt](https://github.com/collegevine/confcrypt), an application for managing config files without the drawbacks inherent in other approaches.

#### How its always been done

Imagining that you have a bunch of sensitive configuration for the application, there are a few options available to you.
I'll discus the details of each in the remainder of the article.
You can:
1) Store a copy of the configuration on each node in each environment
2) Store the configuration in a central location like zookeeper, Heroku config, etc...
3) Encrypt the entire file using an RSA key, or something similar
4) Encrypt only the sensitive variables using local keys or symmetric algorithms w/ a password
5) Use an external key management system to encrypt all or parts of your config

As the application developer, you want to make sure your application is easy for other developers to work on.
This means you'll want it to be easy for a new developer to launch a local version.
You'll also want it to run in CI and production with minimal effort, so that should mean you use the same configuration infrastructure there as well.
Finally, you'll want to make sure changes to your application are easy to review.
Meaning that when the developer sitting next to you adds a new config variable to the code, you want to see that same variable appear in the config in their pull request so you can validate it.

With those requirements in mind, what is the effort involved in making each of the five solutions above work?

The first option, storing a copy of the config unencrypted on each node of the environment immediately fails the PR requirement.
Well, I suppose it doesn't fail it since you can always push the unencrypted passwords to source control.
Although doing so is a bit of a security nightmare, particularly if you don't have tight access control on the source code.
Also, if a copy of the config needs to be present & specific for each environment, that means any time a variable is added or changed the developer (or ops team) need to make many additional unlogged changes across all of the different environments.
Each developer working on the code will also need to know to update their own configuration.
This seems like it will "work", but its certainly not a good situation.

Using a central configuration location is an improvement over simply copying around config files.
In this scenario, each time a dev updates config, they need to log into the central config store & update the parameter for each environment.
Its nice that these changes propagate to all nodes in the environment - whether developer machines or production servers - but devs still need to be really careful here because their changes won't be reviewed before they're made.
I've usually seen this done as a "second set of eyes", meaning an over-the-shoulder review as config variables are changed.
Another nice aspect is that most of the systems that provide centralized config management also log all of the changes & accesses to said config, so you get visibility for free.
But unfortunately, as you've already surmised, this also fails the PR review test because the config is stored in a separate system rather than in source control.
So its pretty easy to forget to add a config variable to one of the many environments.

Encrypting the whole file or encrypting only the sensitive parameters are also reasonable choices.
However, each of them has subtle but expensive flaws.
Encrypting the entire file means that other developers can't easily review that the proper parameter name was added during a review.
They can still tell that the file was changed, so that's certainly better than nothing.
Encrypting the sensitive parts is even better, although it suffers from the "shared key" problem.

The shared key problem is a simple name for the problems that arise when a team of developers are all using the same shared encryption key for their config.
They'll usuall store the key in a password vault like 1Password or LastPass, then each developer pulls the key down locally as part of their onboarding.
The biggest issue here is that there's no way to control the proliferation of the key after someone downloads it from the password vault.
Meaning once its out of the vault its painfully easy to accidentally copy it onto another machine, commit it, etc...
Another problem that crops up is key rotation.

Every time a developer leaves or move into a role where they should no longer have access to production config, the shared key needs to be rotated.
This means a new key is generated, everyone pulls down the new key, then the config is decrypted with the old key and re-encrypted with the new one.
Finally, they new key needs to be pushed into CI or production servers - wherever the config is actually decrypted - before it can finally go live.
That's not a terrible process, but it takes a little while and its easy to make a mistake along the way.

#### A better way

In writing this article I want to suggest a better way to manage configuration.
It combines the nice properties of encrypting only the variables using a local key with using a central config store.
The idea is to use a third-party key management system like AWS' KMS, GCP's Cloud KMS, and Azure's Key Vault.

A KMS provides an API for accessing your encryption keys.
They also provide automatic key rotation, access auditing, and the ability to encrypt/decrypt small values.
This means that if you build a system that never persists the keys, then the shared key problem goes away.

At work we were facing all of these problems as we migrated from Heroku - where we suffered from the issues with centralized config management - onto AWS.
Initially we replicated our existing setup by using AWS Parameter Store, but that turned out to be a nightmare to work with.
Shortly after the migration was complete I wrote a small application named [Confcrypt](https://github.com/collegevine/confcrypt) to combine a KMS with encrypting individual parameters.

The idea was to store our config in Github such that the parameter names were always visible, but the values always encrypted.
After initially getting it working with shared keys, I added KMS support, which turned out to be a game changer.
I'm happy to say that we've been using Confcrypt in production across multiple products for over a year now without any issues!

Give it a shot & let me know if it works or doesn't work for you and your team.

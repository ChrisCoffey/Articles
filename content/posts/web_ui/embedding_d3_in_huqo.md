---
title: "Using D3 on Hugo pages via Shortcodes"
date: 2021-05-01T17:07:29-04:00
draft: true
tags: ["hugo", "d3"]
---

In this post, I explain how to easily embed one or more D3 visualizations directly into Hugo page content.

##### Embedding D3 content Hugo posts with Shortcodes
Using D3 on _any_ page requires loading the D3 library and a script containing the D3 code you want to run.
Both of those tasks require adding `<script>` tags to the page, so you'll need some way to add a pair of script tags.
Additionally, you probably don't want the D3 code to mount its visualization directly to the page's `body`, so you'll need a target element somewhere in the DOM.
The mount element(s) should probably be in the midst of the page's content since most visualizations work best when they're near content that references them.

The simplest way to get D3 into a Hugo page is to change the `markup identifier` for the content to `html` or `htm`, then write the entire post as HTML.
That provides easy access to the `<script>` tag that will contain your D3 Javascript.
But it also means you've written an entire page directly as HTML.
While not necessarily a bad thing, this degree of control is unnecessary and it's much more pleasant to write content in markdown.
Markdown also supports inline HTML, so you could always add the `<script>` tags directly to the content, but this gets messy fast.

Another way - used [elsewhere on this blog]({{< ref "posts/long_reads/heroku_dyno_analysis" >}}) - is custom shortcodes.
Shortcodes allow embedding literal HTML directly into the generated markup wherever you like.
They can take arguments as well but for our purposes, all that's necessary is something simple without any arguments, like this:
``` markdown
Lots of content...
{{%/* d3_viz_shortcode */%}}
More content!
```
For a more thorough discussion of shortcodes, take a look at [Hugo's documentation](https://gohugo.io/content-management/shortcodes/).

The shortcode itself is an HTML snippet located in `layouts/shortcodes`.
You can nest them within sub-directories to help with organization, but need to call the shortcode with a path relative to `layouts/shortcodes/`.
A D3 visualization shortcode needs to _at least_ load a script containing the D3 code.
As far as loading D3, you could either do that within the shortcode snippet or use a custom content type and layout for posts with a visualization that loads D3.
In this example, I've included loading D3 itself inline next to the visualization, although that isn't necessary.

```html
<script type="text/javascript" src="https://d3js.org/d3.v6.js"/>
<div id="viz">
</div>
<script type="text/javascript">
    function gen_viz(){
    ... your code here. Be sure to mount the vizualization to the `#viz`.
    }
    gen_viz()
</script>
```
This is pretty trivial, but there are two pieces worth calling attention to.
First, the shortcode needs to create an element for D3 to mount a visualization to so you can control _where_ on the page the visualization appears.
Hence the empty `<div>`.
Also, note that the second script creates a function rather than inlines the D3 code directly.
This isn't strictly necessary, but it is good hygiene to prevent your script from polluting the global namespace.

And that's all you need to embed a D3 graphic into your Hugo pages _without_ writing raw HTML!

If you've solved this problem differently, I'd love to hear about it in the comments.

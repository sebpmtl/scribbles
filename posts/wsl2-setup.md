---
title: "Montreal Winter & WSL2 Performance"
date: "2026-03-05"
draft: "false"
---
It’s -22°C outside, which is the perfect weather to stay inside and reconfigure a development environment. I’ve finally moved Scribbles entirely into a WSL2 instance running Alpine Linux.

The disk I/O overhead on Windows is real, but when you're working with Erlang, the BEAM doesn't seem to mind as much as Node.js does. I've been profiling the compilation times for the Markdown parser. By using `binary:split` instead of heavy regex for the body content, I shaved 40ms off the build time. In a world of bloated frameworks, those milliseconds feel like a small victory for the DIY spirit.

If you're seeing this post, the sync logic is officially working through the Windows file system boundary and the masonry grid is holding the weight of this paragraph.
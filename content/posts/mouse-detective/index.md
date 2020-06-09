---
title: "Mice Detection in Go Using OpenCV and MachineBox"
date: 2020-06-08T00:40:13-04:00
draft: true
---

{{< figure src="mouse-detective.gif" >}}

## Background

Last week, we had an unwanted visitor. My wife was working late in our COVID-19 office space when she heard something
rustling. She looked over and...

{{< video src="screech.mp4" width="800px" >}}

Did you catch that? Our little mouse visitor quickly scurried to our closet in the lower left corner of the video. Of
course, my wife is horrified and would like to throw the whole house away. How long has he been in the house? How many
do we have? Why, oh why?! With all of the things going on in addition to the pandemic, like the mistaken shooting of
[Breonna Taylor](https://www.nytimes.com/article/breonna-taylor-police.html), the attempted cover up of the killing of
[Ahmaud Arbery](https://www.nytimes.com/article/ahmaud-arbery-shooting-georgia.html),
and the horrible execution of [George Floyd](https://www.nytimes.com/2020/05/29/us/minneapolis-police-george-floyd.html),
this unwanted visitor was a nice reprieve.

We are fortunate to have a camera (a [Wyze Cam Pan](https://www.amazon.com/Wyze-1080p-Indoor-Camera-Vision/dp/B07DGR98VQ))
set up in the basement already and it just happened to catch the path the mouse favored. However, the Wyze Cam saves
videos in one-minute intervals so going through nearly 4-thousand videos looking for a mouse to scurry by in a fraction
of a second would be a major time sync. Seems like a perfect problem for a software engineer.

## Training the model

Being a [systems engineer](/about), I haven't had the need for any machine learning in my day-to-day (yet), but I figured
I would need to train a model to detect the mouse in the videos I had. I've been using Go for most of my side projects
lately, so I unwittingly just searched for:

> golang process video detect

In the results I found some references for [MachineBox](https://machinebox.io/). Looking through the docs it seemed like
their [Objectbox](https://docs.veritone.com/#/developer/machine-box/boxes/objectbox) was what I needed to train a model
to detect the unwanted rodent.

{{< figure src="machine-box-landing.gif" >}}

After setting up a free account with MachineBox, getting the model trained was really straight forward. I used
`docker-compose` to set up the box in a container.

```yaml
version: '3'
services:
  objectbox1:
    image: machinebox/objectbox
    environment:
      - MB_KEY=${MB_KEY}
      - MB_OBJECTBOX_ANNOTATION_TOOL=true
    ports:
      - "8083:8080"
    volumes:
      - objectboxdata:/boxdata
volumes:
  objectboxdata:
```

Once the container was up, I pointed my browser to `http://localhost:8083` and was greeted with the documentation.

{{< figure src="objectbox-landing.png" >}}

Training the model was relatively straight forward using the annotation tool. Since I knew the time my wife actually saw
the mouse, I found the one-minute long video file with her screech. Since it seemed from the UI that the annotation tool
would only accept a URL to the video or image, I wrote a little [file server](https://github.com/grocky/mouse-detective/blob/master/cmd/fileserver/main.go)
so that I could provide a local URL instead of hosting the video somewhere. However, according to their [blog](https://blog.machinebox.io/introducing-objectbox-super-simple-object-detection-90699b92738d) you should be able to mount a folder with the training videos to the container, but I couldn't find it in their docs {{< emoji ":disappointed:" >}}.
I assume the videos would be available in the `/boxdata` mount point.

{{< figure src="annotation-tool.png" caption="Objectbox annotation tool" >}}

I won't go into too much detail on how to annotate the video. Their [demo video](https://www.youtube.com/watch?v=r2qLEhigHgA)
does a decent job describing what you want to do. I found the frames with the mouse, annotated them, and clicked "Start training"
and let it do its thing.

{{< figure src="annotate-mouse.png" caption="Annotation in action" >}}

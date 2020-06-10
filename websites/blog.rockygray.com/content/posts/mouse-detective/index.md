---
title: "Mice Detection in Go Using OpenCV and MachineBox"
date: 2020-06-08T00:40:13-04:00
tags: ["go", "gocv", "machinebox", "graphics", "machine learning"]
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
videos in one-minute intervals so going through nearly 7-thousand videos looking for a mouse to scurry by in a fraction
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
`docker-compose` to set up the box in a container and exported my `MB_KEY` in my shell environment. After a
`docker-compose up` the container was running and I was able to access the box at `http://localhost:8083` and view
the Objectbox documentation.

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

{{< figure src="objectbox-landing.png" caption="*Objectbox landing page*" >}}

Training the model was relatively straight forward using the annotation tool. Since I knew the time my wife actually saw
the mouse, I found the one-minute long video file with her screech. Since it seemed from the UI that the annotation tool
would only accept a URL to the video or image, I wrote a little [file server](https://github.com/grocky/mouse-detective/blob/master/cmd/fileserver/main.go)
so that I could provide a local URL instead of hosting the video somewhere. However, according to their [blog](https://blog.machinebox.io/introducing-objectbox-super-simple-object-detection-90699b92738d) you should be able to mount a folder with the training videos to the container, but I couldn't find it in their docs {{< emoji ":disappointed:" >}}.
I assume the videos would be available in the `/boxdata` mount point.

{{< figure src="annotation-tool.png" caption="*Objectbox annotation tool*" >}}

I won't go into too much detail on how to annotate the video. Their [demo video](https://www.youtube.com/watch?v=r2qLEhigHgA)
does a decent job describing what you want to do. I found the frames with the mouse, annotated them, and clicked "Start training"
and let it do its thing.

{{< figure src="annotate-mouse.png" caption="*Annotation in action*" >}}

## Processing the video

Now for the fun part. At a high level, we have a channel for video frames and a channel for results. The `extractor`
reads in the video file and places each frame in the frames channel. In concurrent goroutines, the `checkers` send the
frames to the objectbox container. If the model detects a mouse, then we save that frame to a file.

{{< figure src="https://github.com/grocky/mouse-detective/raw/master/docs/activity.png" caption="representation of the structure of the program" >}}

### Frame extraction

We'll be using [GoCV](https://gocv.io/) to extract frames from the video. In a goroutine the video
is streamed and each frame is encoded and placed in a channel for processing.

```go
func extractFrames(done <-chan struct{}, filename string) (<-chan frame, <-chan error) {
    framec := make(chan frame)
    errc := make(chan error, 1)

    go func() {
        defer close(framec)

        video, err := gocv.VideoCaptureFile(filename)
        if err != nil {
            errc <- err
            return
        }
        frameMat := gocv.NewMat()

        errc <- func() error {
            n := 1
            for {
                if !video.Read(&frameMat) {
                    return &endOfFile{n}
                }
                buf, err := gocv.IMEncode(gocv.JPEGFileExt, frameMat)
                if err != nil {
                    return err
                }
                select {
                case framec <- frame{n, buf}:
                case <-done:
                    return errors.New("Frame extraction canceled")
                }
                n++
            }
        }()
    }()
    return framec, errc
}
```

### Frame checker

In concurrent goroutines, frames are pulled from the frames channel and sent to the Objectbox container. If the model
detects a mouse in the frame, then we construct a result and place it in the channel.

```go
// channel of frames with mice
results := make(chan result)
var wg sync.WaitGroup
wg.Add(concurrencyF)

// Process the frames by fanning out to `concurrency` workers.
log.Println("Start processing frames")
for i := 0; i < concurrencyF; i++ {
    go func() {
        checker(done, frames, results)
        wg.Done()
    }()
}

// when each all workers are done, close the results channel
go func() {
    wg.Wait()
    close(results)
}()
```

```go
type result struct {
    // the frame number
    frame int
    // The detected bounds
    detectors []objectbox.CheckDetectorResponse
    file      io.Reader
    err       error
}

func checker(done <-chan struct{}, frames <-chan frame, results chan<- result) {
    objectClient := objectbox.New("http://localhost:8083")
    info, err := objectClient.Info()
    if err != nil {
        log.Fatalf("could not get box info: %v", err)
    }
    log.Printf("Connected to box: %s %s %s %d", info.Build, info.Name, info.Status, info.Version)

    // process each frame from in channel
    for f := range frames {
        if f.number == 1 || f.number%10 == 0 {
            log.Printf("Processing frame %d\n", f.number)
        }
        // Set up a ReadWriter to hold the image sent to the model to write the file later.
        var bufferRead bytes.Buffer
        buffer := bytes.NewReader(f.buffer)

		// Send data read by the objectbox request to the buffer.
        tee := io.TeeReader(buffer, &bufferRead)
        resp, err := objectClient.Check(tee)
        detectors := make([]objectbox.CheckDetectorResponse, 0, len(resp.Detectors))

        // flatten detectors and identify found tags
        for _, t := range resp.Detectors {
            if len(t.Objects) > 0 {
                detectors = append(detectors, t)
            }
        }
        if len(detectors) == 0 {
            continue
        }
        select {
        case results <- result{f.number, detectors, &bufferRead, err}:
        case <-done:
            return
        }
    }
}
```

### Results processor

Finally, we drain the results channel and encode the images with the mouse highlighted. The Objectbox response provides
the coordinates of the detected object, so we can use them to draw a rectangle around the found object. I tried using
the standard lib here, but it seemed as though I'd need to iterate through each pixel within a context to draw a
rectangle. I found [gg](https://github.com/fogleman/gg) which is a nice little 2D rendering library.

```go
func processResults(results <-chan result) {
    for r := range results {
        if r.err != nil {
            log.Printf("Frame result with an error: %v\n", r.err)
            continue
        }
        log.Printf("Mouse detected! frame: %d, detectors: %v\n", r.frame, r.detectors)

        image, err := jpeg.Decode(r.file)
        if err != nil {
            log.Printf("Unable to decode image: %v", err)
            continue
        }

        imgCtx := gg.NewContextForImage(image)
        green := color.RGBA{50, 205, 50, 255}
        imgCtx.SetColor(color.Transparent)
        imgCtx.SetStrokeStyle(gg.NewSolidPattern(green))
        imgCtx.SetLineWidth(1)

        for _, d := range r.detectors {
            left := float64(d.Objects[0].Rect.Left)
            top := float64(d.Objects[0].Rect.Top)
            width := float64(d.Objects[0].Rect.Width)
            height := float64(d.Objects[0].Rect.Height)
            imgCtx.DrawRectangle(left, top, width, height)
            imgCtx.Stroke()
        }

        cleanedFilename := strings.ReplaceAll(filenameF, "/", "-")
        frameFile := path.Join(outputDirF, Version+"-"+cleanedFilename+"-"+strconv.Itoa(r.frame)+".jpg")

        err = gg.SaveJPG(frameFile, imgCtx.Image(), 100)
        if err != nil {
            log.Printf("Unable to create image: %v\n", err)
            continue
        }
    }
}
```

Here's a gif of the frames for one of the videos!

{{< figure src="rendered-frames.gif" caption="generated with `convert rendered-frames/*${filedate}* rendered-frames.gif`" >}}

## Wrapping up

With the program set up to process a video, I ran all 4-thousand-ish videos through it to find the first one
with a mouse. Woot!

You can find the full code for this here: [grocky/mouse-detective](https://github.com/grocky/mouse-detective).

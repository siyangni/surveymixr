# surveymixr website showcase

A self-contained page with the estimating R next to the trajectory plot it produces.

## Files to publish

| File | Use |
| --- | --- |
| `index.html` | The static page |
| `trajectories.svg` | The figure (preferred) |
| `trajectories.png` | Raster fallback / social preview |
| `surveymixr-demo.mp4` | 15s 1080p demo (code types, plot appears) |
| `demo-poster.jpg` | Poster frame for the video |

Keep the page files together. `index.html` loads `trajectories.svg` from the same directory.

## Put it on a personal site

**As its own page** (for example `https://siyangni.com/surveymixr/`):

```bash
# copy the three files into the site folder
cp showcase/index.html showcase/trajectories.svg showcase/trajectories.png /path/to/site/surveymixr/
```

**As an embed** on an existing page:

```html
<iframe
  src="/surveymixr/"
  title="surveymixr trajectory demo"
  style="width:100%;height:820px;border:0;background:transparent;"
></iframe>
```

**As a static image** if you only want the figure:

Use `trajectories.png` (180 dpi) or `trajectories.svg`.

**As a looping demo video** (muted, autoplay-safe):

```html
<video
  autoplay muted loop playsinline
  poster="demo-poster.jpg"
  style="width:100%;height:auto;background:#f3eee4;"
>
  <source src="surveymixr-demo.mp4" type="video/mp4" />
</video>
```

The clip is 15 seconds, 1920×1080, about 1.3 MB. The R types in, then the trajectory plot and fit stats resolve beside it.

## Regenerate

From the package root, after `surveymixr` is installed:

```r
source("showcase/fit_demo.R")
source("showcase/plot_demo.R")
```

The fitted object is written to `fit_3class.rds` and is not required to host the page.

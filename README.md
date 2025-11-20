# Configuration

### Create a new repository from the template
Follow [Github's guide](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) to create a new repository from this template.

### Import class and bibliography style files

Download the `.cls` and `.bst` files provided by the target conference or journal into the `src` directory.

Open `Makefile` and point the `CLS` and `BST` variables to the downloaded `.cls` and `.bst` files, respectively.

### Import a paper template

Download the sample paper provided by the target conference or journal, reduce it to a minimum working example and paste its contents into `paper.tex`.

### Reuse glossary entries

Add the following snippet to the preamble of `paper.tex` to pick up the glossary entries provided in this template:
```latex
\input{glossary.tex}
```

### Import figures

Store figures in the `fig` directory. Any `.svg` files in this directory will be automatically converted to `.pdf` using Inkscape.

### Auto-generate results

If you have any auto-generated results, open `Makefile` and add the rules to generate the results in the relevant section at the bottom of the file. Make sure the results are generated in the `res` folder, and list all results the paper depends on in the `RESULTS` variable.

### Import auxiliary documents

If you have any additional Latex documents, e.g. cover letter and summary of changes, which do not include a bibliography, store them in the `src` folder, open `Makefile` and add their names to the `DOCS` variable.

### Track submitted papers

Submitted papers can be saved in the `sub` directory.

You can also create tagged releases:
- In `Makefile`, set `RELEASENAME` to the basename you want to give your releases, e.g. `attention-nips`
- Create a tag, e.g. `git tag v1`
- Run `make release` or `make blind-release`, to build `attention-nips-v1.pdf` or `attention-nips-v1-BLIND.pdf`, respectively

# Usage

Once configured, the repository provides the following Make targets:

|Target                     |Description|
|---------------------------|-----------|
|`results`                  |Regenerate results.|
|`fig`                      |Regenerate any `.pdf` figures from `.svg` figures in `fig`.|
|`paper`                    |Build the paper.|
|`docs`                     |Build all additional documents.|
|`all`                      |Invoke all of the above.|
|`diff REV1=HEAD^ REV2=HEAD`|Generate a diff of the paper between the specified revisions. If omitted, the `REV*` variables default to the mentioned values.|
|`blind`                    |Build an obfuscated version of the paper for double-blind review. The `blindreview` variable implicitly defined by this command can be used within the paper source to conditionally obfuscate content.|
|`arxiv`                    |Build an archive for submission to [arXiv](https://info.arxiv.org/help/submit_tex.html).|
|`release`                  |Create a tagged release of the paper (make sure you are on a tagged git commit).|
|`blind-release`            |Create a tagged release of the obfuscated paper for double-blind review (make sure you are on a tagged git commit). Obfuscated version is the same as built by `make blind`.|
|`clean-fig`                |Delete all artifacts of the `fig` target.|
|`clean-paper`              |Delete all artifacts of the `paper` and `diff` targets.|
|`clean`                    |Delete all artifacts.|

// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
/* Color links */
#show link: set text(fill: rgb(0, 0, 255))

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  title: [EPIB 706: Doctoral Seminar],
  subtitle: [Winter 2026],
  authors: (
    ( name: [Sam Harper],
      affiliation: [McGill University],
      email: [] ),
    ),
  font: ("C059",),
  fontsize: 10pt,
  heading-family: ("C059",),
  sectionnumbering: "1.",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

#link("https://samharper.org/epib706")[Web version]

#table(
  columns: (45%, 55%),
  align: (auto,auto,),
  table.header([#strong[About me];], [#strong[About class];],),
  table.hline(),
  [sam.harper\@mcgill.ca], [#link("https://mycourses2.mcgill.ca/d2l/home/840723")[mycourses2.mcgill.ca/d2l/home/840723];],
  [Hours: by appointment], [Hours: Tuesday/Thursday 1135h-1255h],
  [Office: 2001 McGill College, Room 1262], [Location: 2001 McGill College, Room 1135],
)
= Course Description
<course-description>
EPIB 706 is a PhD-level seminar aimed at providing space for students to engage with overarching concepts critical to the theory and practice of epidemiology, as well to explore recent controversies and debates in the field. The purpose of this course to reinforce your formal methodological coursework by making space to develop and sharpen your critical thinking skills. We will review a selection of papers that range across methods, principles, arguments, and debates in epidemiology and the wider scientific community.

= Eligibility
<eligibility>
Registration in the PhD program in Epidemiology and successful completion of the course sequence in epidemiologic methods (EPIB 703 and EPIB 704) is required. Students who have not completed EPIB 703 and EPIB 704 must obtain the instructor's permission to take the course.

= Course Format
<course-format>
This is a discussion-based course and, quite frankly, it simply won't work well without engagement and participation from all of us (including me). Of course, everyone has their own level of comfort speaking up, as well as varying levels of interest in some of these topics, so I have no expectation that everyone participates equally. What I do ask is that you make a sincere effort to engage with the material, both in terms of the reading and in different forums for discussion. Learning how to respectfully express your opinion about conceptual and methodological issues, and to respectfully listen, engage, and respond to the opinions of others is a core part of being a scientist.

= Evaluation
<evaluation>
== Reading
<reading>
The assigned readings are the core of the course material, and students are expected to carefully and critically read each assignment #emph[before] class. To facilitate student engagement with the reading we will use the online tool #link("http://perusall.com")[Perusall] for all required readings. Perusall is a reading platform in which students (and faculty) annotate texts collaboratively alongside one another. More information on how Perusall works and how it is integrated into the course is available #link("https://asuonline.wistia.com/medias/dvaftxxad7")[here] (thank you Arizona State!). To access Perusall through MyCourses, navigate to Content \> Readings \> Perusall, and then click the "Open Link" button. This will take you to the Perusall site and automatically register you as a member of the course. If you are having any trouble accessing the readings through Perusall contact me right away. I will not be using Perusall's grading features, but I expect you to read, post questions, respond to other students questions and answers, and to take an active role in generating productive discussion.

A couple of features of Persuall that you may want to use:

+ Tagging with \@mentions. You can more directly promote interactions by using the \@name, \@conversation, and \@everyone features. Students (and instructors) will be notified by email and in the app whenever they \@mention each other.

+ Identifying themes with \#hashtags. It seems dated now that Twitter is all but lost, but using hastags can help to develop and build themes for the course. Students (and instructors) can then see in one place all comments that have a particular \#hashtag.

+ Upvoting and question flags. You can upvote each others' comments and questions to indicate that they found a particular comment helpful, or that they have the same question. It's not a popularity contest, but this helps to provide some feedback on the quality of the discussion and responses. Students can also flag a comment of theirs as a question if Perusall doesn't automatically detect it as such.

== Writing
<writing>
The discussions in the course are meant to activate your critical thinking skills, and to encourage you to synthesize your own thoughts on the material, particularly as it may relate to your area of research interest. Toward that end, over the course of the semester you will be asked to submit #strong[one] original, critical essay that explores a topic of relevance to epidemiologic science. It may be a direct response to material that we read or discuss in class, or it may be an essay exploring other topics relevant to your work that demonstrate a good-faith effort to engage with the class material. These should take the form of a commentary similar (in spirit) to those we have read during the semester, and should be no longer than 2500 words. An outline of the essay, including the basic arguments you want to make, is due on #text(fill: red)[#strong[March 17, 2026];] and the final essay is due on #text(fill: red)[#strong[April 16, 2026];]. I will provide examples of what I think are good pieces of writing to aspire to. And who knows, you just may end up publishing what you write for this course!#footnote[The published paper by Goulden assigned for Unit 3 was written for EPIB 706.]

== Use of Generative AI Tools
<use-of-generative-ai-tools>
Apart from critical reading and participating in group discussion, the main assignment in this course is the critical essay. I expect this to be an original piece of scholarship that demonstrates your #emph[own] reflections and engagement with the scholarship in the area you choose to focus on. I encourage you to avoid the use of generative AI tools in this course, especially for writing assignments. Of course these tools have upsides and can save time for some tasks, but they are not well suited to critical thinking and are unlikely to be able to write original work in your voice. Remember that they do not actually think like humans do; they are just prediction algorithms based on highly specific training data. If you do choose to use such tools, it is your responsibility to clearly indicate where and how you used them.

== Engagement
<engagement>
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Leading Discussion
]
)
]
In addition to the writing assignment, each student will be asked to lead #strong[at least one] day of discussion among the topics that we will cover (and probably more than one for most of you). For that session, you will come prepared to #emph[briefly] summarize the material we have read, and to prepare some discussion points to help keep the conversation moving. I have created a Google spreadsheet with the current days for each topic #link("https://docs.google.com/spreadsheets/d/1njZXu5oLeYKnTOYkb6NZVS90Lgk4aQ6C5yXGdqOTCi0/edit?usp=sharing")[here];. Please sign-up for a session and we can have a discussion about the readings and where to draw on other resources for the topic. Note: We have 24 sessions and 16 students this year, so not everyone is required to lead 2 sessions. You should be able to sort this out, but if the remaining slots don't get filled I will happily assign them.

Although each class session is 1.5 hours, there will inevitably be topics that come up that we can't fully address in class. I encourage you to use the #link("https://mycourses2.mcgill.ca/d2l/le/840723/discussions/List")[Discussion] section of MyCourses to post questions or comments there. In past years I have also used this as a place to occasionally post links to additional readings for those interested.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Participation
]
)
]
Real engagement means #emph[active] participation. This can take many forms, but for some general guidance, this means:

- Showing up for each class #emph[having read and engaged with the material assigned];. It will help facilitate discussion if you could aim to contribute at least 2-3 points for discussion or questions about the material in Perusall, and bring those to class;

- Focusing during class discussion and avoiding distractions, and being present and intellectually engaged during the discussion;

- Asking questions about anything in the readings that seems unclear or objectionable (in class, outside class, online). This can include both specific ideas from the readings, as well as synthesizing or finding themes common to different readings or our discussion;

- Offering respectful arguments and responses, and respectfully listening to the arguments and responses of others. Contributions should be relevant and helpful and demonstrate that you are engaging with the material being discussed at the time, and that you are well-prepared for class.

= Grading
<grading>
The course is pass-fail. To pass the course, students must actively participate in class discussions (as described above), lead at least one class discussion, and submit both the outline and final version of the written assignment on time.

= Course Outline (A "baker's dozen" of questions)
<course-outline-a-bakers-dozen-of-questions>
Why are we doing this?

Because this is not a didactic course that is focused on learning methods or technical skills, I owe it to you to provide some justification for the topics and readings I've chosen, as well as for why I think this material would be useful for your doctoral training. For each set of assigned material (the 'What'), I've included a brief rationale (the 'Why'). I hope you find it helpful.

A final note about the outline. In an effort to make this course as dynamic and helpful to students as possible, the list of topics and readings below is subject to change. Enthusiasm (or lack thereof) for certain topics may lead us to revise, drop, add, or replace some readings or entire topics as we go. I promise to entertain any suggestions from you for changes, but I may also disagree if I feel certain topics or readings are too important to replace.

== Unit 1: What is the present and future of epidemiology as a discipline?
<unit-1-what-is-the-present-and-future-of-epidemiology-as-a-discipline>
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-01-06: Course introduction
]
)
]
- Administrative aspects of the course.
- Round table -- introductions.
- Discussion of objectives and competencies.

In the first substantive session we will talk generally about high-level questions regarding the discipline of epidemiology as a whole. Although it is early on in your training, I think it is valuable for you to be aware of these broader discussions about where the field stands in relation to its past, and what the appropriate balance should be between descriptive, causal, or implementation questions. Having some knowledge about the intellectual history of different concepts ("risk factor epidemiology", "consequential epidemiology") will help you to figure out where your own work stands in relation to the discipline as a whole.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-01-08: Reflections on epidemiology's past and present
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<daveysmith2019>, form: "prose")

- #cite(<lesko2020>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The Davey Smith paper provides a bit of historical orientation to the 'modern' epidemiology training you are getting, as well as a critique of it in relation to epidemiology's past. I chose the Lesko et al.~paper because it focuses on the relationship between the tools of epidemiology (about which you are learning a lot in this first year) and the kinds of questions that can be answered with those tools. In particular, they focus on differences between purely descriptive questions, questions about synthesized evidence on causal relationships, and questions about specific interventions for which we want to estimate a causal effect. I also like that it was written by early career researchers whose training is in many ways similar to your own.

== Unit 2: What is your research question?
<unit-2-what-is-your-research-question>
Asking good questions is central to advancing epidemiologic knowledge, but what makes a question 'good'? Is 'novelty' more important than making incremental progress? Should it matter whether a given question will produce 'actionable' evidence? And is it problematic if a study's methods are not well aligned with the question it seeks to answer? Is it wasteful (or, even unethical) to produce such work?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-01-13: Does it matter whether questions and methods align?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<hernan2019>, form: "prose")

- #cite(<kaufman2017>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
What is the relationship between research questions and methods? Should we just use multivariable regression for everything? Does it actually matter? The paper by Hernan and colleagues tries to lay out how questions and methods should be aligned in empirical data science research. This paper was written when enthusiasm for machine learning and other empirical data science algorithms began achieving a high degree of influence, and their paper aims to try and clarify the utility of being clear about the question being asked, the methods used to answer it, and the role of expert knowledge in generating the result. Kaufman's paper is more focused on methods and questions for descriptive epidemiologic studies, and the thorny problems that come with decisions about when and what to adjust for in these studies.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-01-15: Estimands and practical questions
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<kahan2023>, form: "prose")

- #cite(<albers2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
What is the relationship between estimands (the quantities we seek to estimate) and research questions? We start with an overview from Kahan and colleagues on estimands and how to use them in answering research questions. The second paper by Albers et al.~is focused on applying this kind of framework to a figure out how one might answer a question like whether physical activity may affect survival after a cancer diagnosis.

== Unit 3: How important is formal causal inference?
<unit-3-how-important-is-formal-causal-inference>
Much of modern epidemiologic training now starts with the introduction of potential outcomes framework, as well as introducing DAGs as a way to draw and consider assumptions needed for doing causal inference. What are the implications of using these frameworks for the kinds of questions that can be asked and answered in epidemiology? Do we risk restricting ourselves to 'formal' methods when it comes to causal questions, or are other alternatives possible? These are fundamental questions about the nature of epidemiologic inquiry, and it is useful for you to consider the benefits and drawbacks that may come with adopting this epistemological stance. As you progress in your training, you'll need to decide on how you will approach questions of causal inference both in your own work and in your evaluations of the wider epidemiologic literature.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-01-20: Are 'modern' methods worth it?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<goulden2025>, form: "prose")

- #cite(<labrecque2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The first set of papers for this session (one of which was written for this class a few years ago) are focused on the benefits and potential drawbacks of the use of 'modern' causal inference methods in epidemiology.#footnote[Both of these authors have PhDs from this department, so I realize this feels a little narrow in terms of voices];. Have these methods generated new and important epidemiologic discoveries that 'old' methods would have missed? Goulden is skeptical that new methods have demonstrated their worth, and also asks how we would know if they had? Labrecque responds by trying to place Goulden's critique in the larger discussion of knowing when and where it may make the most sense to apply the 'right' methods for the question at hand.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-01-22: Are well-defined interventions needed for causal questions?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<schwartz2016>, form: "prose")

- #cite(<hernan2016b>, form: "prose")

- #cite(<schwartz2017>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The second set of readings for this week engages with a more specific critique of 'modern' causal inference methods, namely, the notion that 'good' causal questions are based on well-defined interventions. This is a more recent argument, largely associated with Miguel Hernan and linked to the idea of using 'target trials' to formulate questions for observational studies.

As academics are wont to do, there has been some pushback against this idea, notably by Sharon Schwartz, another long-term and thoughtful critic of epidemiology (see her nice 1999 pre-causal-inference-revolution paper#footnote[#cite(<schwartz1999>, form: "prose");] in Am J Public Health on the consequences of what she called, 'Type III error' which is about asking the wrong question). She and other critics are pushing back against this idea and trying to understand it's implications (again) for the kinds of #emph[causal] questions we can answer.

== Unit 4: How should we study non-manipulable exposures?
<unit-4-how-should-we-study-non-manipulable-exposures>
Longstanding debates about whether exposures that are not directly (or perhaps even theoretically) manipulable, such as race, ethnicity, sex, or country-of-birth, present important challenges for the counterfactual models of causal inference you have been learning about. This set of readings aims to try and clarify some of these conceptual questions and derive potential paths forward that respect the "rules" of causal inference but that can also provide evidence that may be useful for reducing differences in health across non-manipulable factors.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-01-27: Are non-manipulable exposures causes?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<vanderweele2014>, form: "prose")

- #cite(<glymour2017>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The paper by Vanderweele and Robinson tries to address the issue of non-manipulable exposures (specifically race) in a way that respects the complexity of this kind of exposure, but attempts to move forward to see whether it is helpful to reframe the question to how interventions on factors plausibly affected by race may affect racial differences in health. Meanwhile, Glymour and Spiegelman offer more of a defense of the idea that non-manipulable factors are causes and deserve the same kind of consideration and treatment as other exposures we study routinely in epidemiology. What do you think? How can we balance methodological rigor and concerns for equity?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-01-29: Case study: race in clinical treatment.
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<vyas2020>, form: "prose")

- #cite(<coots2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
How should we think about a factor like race when considering disease risk? Taking a bit of a break from conceptual readings on questions and causal inference, in the second session we delve into a case study of the challenges in the use of race in clinical medicine. Should we use race as a factor in recommending treatments to patients? Does it matter whether or not race is a cause of the outcome, or whether including race might affect inequalities? The two papers from Vyas et al.~and Coots et al.~arrive at somewhate different arguments regarding whether or not race should be included, and I think they provide a rich set of issues to discuss that complement the arguments about how we should study non-manipulable exposures in epidemiology.

== Unit 5: Should we try to randomize?
<unit-5-should-we-try-to-randomize>
Okay, we've talked about the role of asking good questions, whether non-manipulable factors are causes and ways to investigate them, and whether we need well-specified interventions for causal questions, but let's now turn toward more practical concerns (ha). You want to study exposure $X$, which is not known to be either harmful or beneficial, #emph[can] be ethically and feasibly manipulated, and has plausible reasons for why it should affect $Y$. What kind of design should you use? Should you try and design a randomized evaluation? What would be the benefits? What drawbacks? What are the implications for external generalizability or understanding the mechanisms through which it may affect $Y$?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-02-03: Are RCT's special?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<deaton2018>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Deaton and Cartwright's paper provides an overview of core philosophical, conceptual, and statistical concepts of randomized trials, and a lot of comments on their benefits and drawbacks. As epidemiologists, I think you will benefit from getting into the weeds a bit about randomized designs and grappling with questions about when and where they might be appropriate.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-02-05: What if we can't randomize?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<pearce2023>, form: "prose")

- #cite(<dang2023>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Despite some important strengths of randomized designs, especially for exchangeability, in some cases it just won't be feasible or ethical to pursue a randomized design. What then? Anything goes? Just plug all the confounders into your regression and hope for the best? There are still good reasons to consider thinking conceptually about the trial you would design if feasibility and ethical issues were irrelevant, and then attempting to pursue an observational design that corresponds as closely as possible to your hypothetical "target trial". The target trial framework has become much more common in recent years, but it is still worth considering its strengths and limitations. Pearce and Vandenbroucke argue that target trials have important limitations and should not be the default approach when randomization is infeasible. Dang and Balzer disagree and try to show how a more expanded view of the target trial approach can enhance causal inference.

== Unit 6: Do we need representative samples?
<unit-6-do-we-need-representative-samples>
Okay, so now suppose that we've decided on a question and a (randomized or non-randomized) design. Who should be in our sample? Is it important that we obtain a random sample of our target population, or can we use a convenience sample? And how does this change depending on the goal of our study, i.e., to estimate a prevalence #emph[versus] develop a prediction model #emph[versus] estimate a causal effect?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-02-10: Should our studies be representative?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<rothman2013>, form: "prose")

- #cite(<rudolph2023>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Debates about whether studies designed to estimate causal effects need to be representative, or alternatively should purposefully be designed not to be representative, have been persistent in epidemiology, but have also become more pressing given increasing concerns for generalizability. This paper by Rothman arguing that causal studies should avoid representative samples created a stir some years ago, and has produced some additional empirical work on how much this matters. This is complemented by a recent paper from Rudolph et al.~putting this into a more modern context and discussing the importance of clearly defining the target population. These issues are important for when you are both producing and consuming research, and it will be worthwhile to struggle a bit with them.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-02-12: Case studies in moving beyond the sample.
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<stamatakis2021>, form: "prose")

- #cite(<downes2020a>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Once again, let's take a break and look at a couple of case studies regarding the importance (or non-importance) of representative samples. Do the consequences actually matter? Here we have two papers aimed at making inferences with non-representative samples. Stamatakis et al.~are focused on estimating associations between measures of lifestyle and mortality from a volunteer biobank, whereas Downes and Carlin have more descriptive aims and utilize different methods.

== Unit 7: How should we make statistical inferences?
<unit-7-how-should-we-make-statistical-inferences>
This question probably won't go away over the course of your PhD training, or in the near future, so it is important to grapple with it. What are the consequences of the way we currently teach and use p-values (or 95% confidence intervals), how does it affect the way you read and interpret evidence? Should we banish the term "statistically significant" and, if so, why? How will you argue against peer reviewers and journal editors (or even your supervisors) that demand you include p-values (or, even worse, stars for levels of 'significance') in your papers? This is a core issue of moving from sampled data and analysis to the kind of inferences you will make about causal effects. How will you approach it?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-02-17: How should we use p-values?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<wasserstein2019>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Wasserstein et al.~provide a series of arguments for abandoning p-value thresholds, some of which you are likely to have heard before, but there is much more in this paper. They make a number of positive arguments for how we #emph[should] be conducting inference, and interpreting the results of research, and they aim to try and provide solid foundations for being more thoughtful about how to interpret evidence.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-02-19: What are alternatives to p-values?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<greenland2022>, form: "prose")

- #cite(<harhay2022>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Given the Wasserstein paper's suggestion to abandon statistical significance, questions naturally arise about how we should do inference instead of using p-values. Most epidemiologists are trained to use confidence intervals rather than p-values, but it does not appear to have changed the basic problem of scientists dichotomizing evidence using arbitrary statistical thresholds. These papers attempt to provide some alternative avenues to explore. Greenland et al.~continue their quest to promote notions of 'compatibility' rather than significance. I included the Harhay et al.~paper because it shows how to provide a more nuanced interpretation of a 'non-significant' RCT using straightforward Bayesian inference. This should get you thinking about how you will manage your inferences in your own research

== Unit 8: How bad can it be?
<unit-8-how-bad-can-it-be>
This unit's readings move beyond inference on the main quantitative question or hypothesis of interest and are focused on concepts and methods relevant to testing and probing the assumptions needed to interpret quantitative evidence. These ideas are crucial for thinking about testing alternative explanations for observed findings, and quantifying the assumptions needed to do so.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-02-24: Good and bad critiques
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<small2023>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Small uses the famous example of smoking and lung cancer (among others) to discuss different ways of approaching an observational study with a critical eye. Taking historical cues from early proponents of sensitivity analysis (Bross, Cornfield), he makes a case for positive ways to critique observational studies, as well as keeping hypothetical critics in mind when designing your won studies. Nothing too formal or methodological here, just a focus on developing sound, credible arguments to critique a study.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-02-26: How can we quantify our assumptions?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<lash2014>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Lash et al.~provide a long overview of good practices for quantitative bias analysis, discussing both the motivation for why one would want to to conduct bias analysis and the mechanics of how to do so (choosing parameters, considering uncertainty). These methods are valuable for most study designs, but may be especially so for "garden variety" observational studies that must rely on basic regression adjustment to have any hope of making causal inferences.

#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Winter Break
]
)
]
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-03-03: No class
]
)
]
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-03-05: No class
]
)
]
== Unit 9: To whom do epidemiologic results apply?
<unit-9-to-whom-do-epidemiologic-results-apply>
We have spent time now thinking about developing questions, considering whether to randomize treatments, how to sample and make statistical inferences about population or causal parameters, and thinking about how to address biases. This week, we are moving on to thinking about the question of to whom our study results should apply. These are core questions that come up in the context of evaluating strengths and weaknesses of studies in peer review (or perhaps grant review), and whether the results of studies may provide actionable evidence.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-03-10: How should we think about generalizing to other populations?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<lesko2017>, form: "prose")

- #cite(<lesko2020a>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Despite the clear importance of considering to whom study results should apply, there has been little formal work on what assumptions are needed to derive quantitative estimates of effects in different external populations, whether those refer to the target population or a population that is external to the target. Lesko et al.'s 2017 paper provides a formal approach to these issues, using a potential outcomes perspective. The second paper by Lekso et al.~is less formal and provides a bit more context for thinking about how to integrate both internal and external validity in the context of a single study. Together these two papers argue that we should consider formal approaches to generalizability, and provide some guidance as to what assumptions (and potentially data) would be needed to do so.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-03-12: Should we generalize to individuals?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<roberts2024>, form: "prose")

- #cite(<paneth2020>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The second part of our readings on extending results to other populations reframes the question not about transporting results to a different sample, but about how to (and whether we can) derive reliable predictions about treatment effects at the individual level. This is related to ongoing discussions about the concepts of "precision" epidemiology or precision public health, and whether these ideas are really novel or just ways of re-branding what we have always considered in public health, which is targeting when it comes to interventions. There have emerged different 'camps' of those more and less enthusiastic about this idea, and these two papers are meant to provide an overview of some of these issues.

== Unit 10: How should we communicate epidemiologic evidence?
<unit-10-how-should-we-communicate-epidemiologic-evidence>
This week we will be reading more about the (possible) tension between our duties as epidemiologic scientists to try and report evidence in a dispassionate way, and the sometimes pressing need for action to tackle pressing health problems when evidence is uncertain, or in contrast to our expectations.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-03-17: How should we discuss epidemiologic results?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<savitz2016>, form: "prose")

- #cite(<blastland2020>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
This session's readings are focused more on how to grapple with and communicate uncertainty in epidemiologic findings, both to other scientists (e.g., in peer-reviewed papers) and to the public or to other stakeholders. The chapter by Savitz and Wellenius provides some high-level guidance and advice to epidemiologists about their duties to describe evidence in a dispassionate way, but also to make good faith efforts to distill findings in ways suitably tailored for different audiences. Some additional discussion of how to consider biases across different studies when synthesizing evidence is also included. The piece by Blastland et al.~is more direct in providing advice to scientists on how to communicate about evidence, largely arguing that our duties are to be transparent in reporting, especially about uncertainty, rather than attempting to persuade or change opinions.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-03-19: How should we think about research 'impact'?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<bann2024>, form: "prose")

- #cite(<lesko2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
When your study is finished, how should the results be communicated? Should you consider policy implications? Create a press release? How can we decide whether the research we do has 'impact'? These two papers provide some different perspectives on these questions. Bann et al.~make the case that single studies should (in most cases) refrain from making claims about policy. In a very recent paper Lesko et al.~try and provide a more systematic framework for thinking about potential impact, considering disease burden, potential interventions, and the strength of evidence.

== Unit 11: How should we put together all of the evidence?
<unit-11-how-should-we-put-together-all-of-the-evidence>
This week we are going to talk more about how to put together and think about diverse lines of evidence to come to some sort of judgement about causal effects. Most of you will have heard (and I agree) that a single study is unlikely to be sufficient to generate certainty about a given exposure-outcome effect. There may be special circumstances (e.g, vaccine trials for COVID-19), but generally we are starting from a place where we have to consider various lines of argument and evidence to inform our thinking. How should we put all of this evidence together?

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-03-24: Can "triangulation" help?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<labrecque2024>, form: "prose")

- #cite(<gutierrez2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
You may have seen various papers talk about the concept of 'triangulation' in thinking about evidence. Here we have two papers that pursue somewhat different approaches to the idea. Labrecque and Swanson focus on a more formal approach anchored in causal inference. Gutierrez et al.~take a somewhat more expansive view, but the basic idea here is to pull together (sometimes by design) data sources that may trade off different kinds of biases in order to see whether results are consistent across various settings. I encourage you to consider whether you think it is a useful approach.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-03-26: Does meta-analysis help or hurt?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<hiltonboon2022>, form: "prose")

- #cite(<savitz2021a>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
Meta-analysis of a systematic review has become the dominant method for summarizing epidemiologic evidence, but comes with a large set of challenges, particularly for observational studies. These two papers provide an overview of some of the challenges of how these contribute to evidence, and whether they are ultimately useful for informing causal inference about the effects of exposures.

== Unit 12: Is research (including epidemiology) reliable?
<unit-12-is-research-including-epidemiology-reliable>
This week we are stepping away a bit from epidemiology only, and focusing on larger questions related to potential problems that may be widespread across scientific research (obviously, including epidemiology). Can or should we trust most published research? Is it reliable? Is it replicable and, if not, is that really a problem? Many of these issues have come up in the context of something that has been called the "replication crisis" in science, much of which started when some high-profile lab and social science projects were found not to replicate using similar designs and methods.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-03-31: Is science broken?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<baker2016>, form: "prose")

- #cite(<szabo2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The short paper by Baker is old but documents a widespread agreement (across disciplines) that there are problems with the reliability of science. The chapter by Szabo from his recently published book #emph[Unreliable] about problems in biomedical science focuses largely on problems in the pipeline for publishing scientific research. You may be familiar with some of these issues (e.g., so-called 'predatory' journals), but the scale of these challenges has increased as more research output is generated, as well as being exacerbated by generative AI. These are challenging issues and may pose serious dilemmas for early career researchers facing ever greater pressure to publish more and more.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-04-02: What are some potential solutions?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<mathur2023>, form: "prose")

- #cite(<mcelreath2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
The second session features a paper by Mathur and Fox that is more focused on outlining and describing some potential solutions to problems with unreliable research, including study pre-registration and pre-analysis plans, registered reports or 'results-blind' peer review, sharing of research materials, including data and code, and changing incentives around publication and grants - all core processes for modern working scientists. A recent blog post by Richard McElreath is a bit more skeptical about potential science reforms.

== Unit 13: Will AI save us or kill us?
<unit-13-will-ai-save-us-or-kill-us>
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Tuesday 2026-04-07: Can we work with AI in our analyses?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<dobler2025>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
AI and chatbots are now ubiquitous, and that extends to science in general and epidemiology in particular. Should we use them? If so, how, and for what purposes? Dobler and colleagues provide an overview from the lens of biostatistics about how AI may be useful in epidemiologic research, as well as some of the pitfalls to avoid.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Thursday 2026-04-09: Is AI too much of a good thing?
]
)
]
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
What:
]
)
]
- #cite(<sengupta2025>, form: "prose")

- #cite(<messeri2024>, form: "prose")

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Why:
]
)
]
How might the use of AI change science more generally, and what are the consequences for training programs? Sen Gupta argues that recent improvements in AI are so powerful that they may now fundamentally threaten the traditional model of scientific training, and we need to change the way we are training PhD students. On the other hand, Messeri and Crockett are more skeptical of whether AI can and will lead to better understanding or improved discoveries in science. These are fundamental questions that the new generation of epidemiologists are going to have to grapple with, and it is worth your time to start thinking critically about how and why you will use AI in your own work.

= Academic Integrity
<academic-integrity>
The Department of Epidemiology and Biostatistics has asked instructors to remind students of McGill University regulations regarding academic integrity and plagiarism. These are excerpted below.

== Academic offences
<academic-offences>
The integrity of University academic life and of the degrees the University confers is dependent upon the honesty and soundness of the teacher- student learning relationship and, as well, that of the evaluation process. Conduct by any member of the University community that adversely affects this relationship or this process must, therefore, be considered a serious offence. McGill University values academic integrity. Therefore all students must understand the meaning and consequences of cheating, plagiarism and other academic offences under the Code of Student Conduct and Disciplinary Procedures (see http:\/\/www.mcgill.ca/integrity for more information).

L'université McGill attache une haute importance à l'honnêteté académique. Il incombe par conséquent à tous les étudiants de comprendre ce que l'on entend par tricherie, plagiat et autres infractions académiques, ainsi que les conséquences que peuvent avoir de telles actions, selon le Code de conduite de l'étudiant et des procédures disciplinaires (pour de plus amples renseignements, veuillez consulter le site http:\/\/www.mcgill.ca/integrity).

== Plagarism
<plagarism>
- No student shall, with intent to deceive, represent the work of another person as his or her own in any academic writing, essay, thesis, research report, project or assignment submitted in a course or program of study or represent as his or her own an entire essay or work of another, whether the material so represented constitutes a part or the entirety of the work submitted.

- Upon demonstration that the student has represented and submitted another person's work as his or her own, it shall be presumed that the student intended to deceive; the student shall bear the burden of rebutting this presumption by evidence satisfying the person or body hearing the case that no such intent existed, notwithstanding Article 22 of the Charter of Student Rights.

- No student shall contribute any work to another student with the knowledge that the latter may submit the work in part or whole as his or her own. Receipt of payment for work contributed shall be cause for presumption that the student had such knowledge; the student shall bear the burden of rebutting this presumption by evidence satisfying the person or body hearing the case that no such intent existed (notwithstanding Article 22 of the Charter of Students' Rights).

== Cheating
<cheating>
No student shall:#footnote[Downloaded and excerpted from A Handbook on Student Rights and Responsibilities, 2010. Available on-line at http:\/\/www.mcgill.ca/students/srr/academicrights/integrity/cheating]

- In the course of an examination obtain or attempt to obtain information from another student or unauthorized source or give or attempt to give information to another student or possess, use or attempt to use any unauthorized material;

- Represent or attempt to represent oneself as another or have or attempt to have oneself represented by another in the taking of an examination, preparation of a paper or other similar activity;

- Submit in any course or program of study, without both the knowledge and approval of the person to whom it is submitted, all or a substantial portion of any academic writing, essay, thesis, research report, project or assignment for which credit has previously been obtained or which has been or is being submitted in another course or program of study in the University or elsewhere;

- Submit in any course or program of study any academic writing, essay, thesis, research report, project or assignment containing a statement of fact known by the student to be false or a reference to a source which reference or source has been fabricated.

= Language Rights
<language-rights>
"In accord with McGill University's Charter of Students' Rights, students in this course have the right to submit in English or in French any written work that is to be graded. This does not apply to courses in which acquiring proficiency in a language is one of the objectives."

« Conformément à la Charte des droits de l'étudiant de l'Université McGill, chaque étudiant a le droit de soumettre en français ou en anglais tout travail écrit devant être noté (sauf dans le cas des cours dont l'un des objets est la maîtrise d'une langue). »

 
  
#set bibliography(style: "chicago-syllabus.csl") 


#bibliography("EPIB706.bib")


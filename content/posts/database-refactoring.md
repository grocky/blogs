---
title: "Refactoring is good for your code and databases too!"
featured: true
date: 2019-05-20T08:00:00-04:00
tags: ["database", "refactoring", "mysql"]
---

# Refactoring is good for your code and databases too!

Ever since reading [Refactoring](https://martinfowler.com/books/refactoring.html) by Martin Fowler, I have gained a healthy amount of respect for the process and mechanics of refactoring code (i.e., a technique for restructuring an existing body of code without changing its behavior).
It identifies some common "code smells" and provides a step-by-step guide to refactoring the code into a better design.
Instead of plowing through and refactoring all the things at once and then playing whack-a-mole to get the tests green again, following the principles described in the book allows you to be methodical and precise in the way you reshape your code.
It certainly has deepened my appreciation for the craftsmanship of writing code and reduced the chances that I get myself into a "_Why is everything broken???_" situation.

<p align="center">
    <img src="/database-refactoring/frustrated.jpg" alt="Frustrated" align="center" style="height: 350px;"/>
</p>

> From *[Storyblocks](https://www.storyblocks.com/)*

Recently, I conducted a database change that moved some columns around to different tables and introduced a new schema - something I have done dozens of times, though maybe a little brazenly.
Typically, in my projects, I run migrations then deploy the application.
Running migrations is an explicit step within the deployment process and not tied to application startup to remove the chance of race conditions when there are multiple application instances.

<p align="center">
    <img src="/database-refactoring/diagrams/migrations-deployment.png" alt="migrations deployment" style="height: 350px;"/>
</p>

*Fig. 1: Deployment Process*

This process works really well for deploying database changes.
However, if you change the database schema in a way that is not backwards compatible (e.g. rename, remove, or move a column), you may risk some downtime or have some requests fail while the new version of your application is deployed.
For example, in *Fig. 2* below, deploying a change that moves a column from one table to another results in request failures from the time the migration is applied to when the previous version of the application is removed.

<p align="center">
    <img src="/database-refactoring/diagrams/timeline-deployment-1.png" alt="timeline of application deployment" style="height: 350px;"/>
</p>

*Fig. 2: Original Deployment Timeline*

Previously, I had the attitude that failures during deployment were acceptable.
_I had 5% of requests fail for 5 minutes? Meh. As long as the new code is working as expected, I am good._
However, I wanted to deploy these type of changes without any failures because I worked with critical data and a 1% request failure rate was a _really_ big deal.
I quickly found [Refactoring Databases](https://martinfowler.com/books/refactoringDatabases.html) by Scott Ambler and Pramod Sadalage and was delighted to see it had similar principles to break down data model refactors into safe, manageable pieces.

Revisiting the example of moving a column from one table to another, the key is to keep the schema backwards compatible to allow for a smooth transition between different versions of the application and allow for application rollbacks.
You can do this in a couple of phases where the new column location and updated application logic is grouped into one deployment and the removal of the old column with a following deployment.
This prevents errors from schema misalignment while transitioning between application versions.
This also introduces a _Transition Period_ where you ensure the new application and schema is working as expected before cleaning up.
For scenarios where the database is a back-end for multiple applications, this period allows enough time for applications to migrate over to the new schema.
The _Clean Up_ phase could be weeks or months in the future, but with the appropriate triggers the data will remain in-sync.

<p align="center">
    <img src="/database-refactoring/diagrams/timeline-deployment-2.png" alt="timeline of clean application deployment" style="height: 350px;"/>
</p>

*Fig. 3: Refactored Deployment Timeline*

For destructive schema migrations (e.g., a change that would require renaming or removing a column), the refactoring procedure is as follows:

1. Phase 1: **Deprecate Columns**
    * If you are moving a column, write a migration to add columns and then update the application to use the new column location.
        * When moving a column, you will need to move data over to the new column and set up triggers to synchronize data between the columns.
    * If you are removing a column, then update the application to stop using the column to be removed.
    * Deploy.
1. Phase 2: **Transition Period**
1. Phase 3: **Clean Up**
    * Write a migration that removes the previously used column.
    * Deploy.

There are many more patterns and techniques for refactoring database schemas that provide a safe, methodical process to alter production schemas and I encourage you to explore them.
Here is a quick list of references I have found useful that should set you on the right path:

- https://martinfowler.com/books/refactoringDatabases.html
- https://databaserefactoring.com/

> This was originally posted on [Medium](https://medium.com/@rocky.grayjr/refactoring-is-good-for-your-code-and-databases-too-aa4579900235)

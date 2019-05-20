# Refactoring is good for your code and databases too!

Ever since reading [Refactoring](https://martinfowler.com/books/refactoring.html) by Martin Fowler, I have gained a healthy amount of respect for the process and mechanics of refactoring code (i.e., a technique for restructuring an existing body of code without changing its behavior).
It identifies some common "code smells" and provides a step-by-step guide to refactoring the code into a better design.
Instead of plowing through and refactoring all the things at once and then playing whack-a-mole to get the tests green again, following the principles described in the book allows you to be methodical and precise in the way you reshape your code.
It certainly has deepened my appreciation for the crafstmanship of writing code and reduced the chances that I get myself into a "_Why is everything broken???_" situation.

<p align="center">
    <img src="./imgs/frustrated.jpg" alt="Frustrated" align="center" style="height: 350px;"/>
</p>

*[Storyblocks](https://www.storyblocks.com/)*

Recently, I conducted a database change that moved some columns around to different tables and introduced a new schema - something I have done dozens of times, though maybe a little brazenly.
Typically, in my projects, I run migrations then deploy the application.
Running migrations is an explicit step within the deployment process and not tied to application startup to remove the chance of race conditions when there are multiple application instances.

<p align="center">
    <img src="./imgs/diagrams/migrations-deployment.png" alt="migrations deployment" style="height: 350px;"/>
</p>

*Fig. 1: Deployment Process*

This process works really well for deploying database changes.
However, if you change the database schema in a way that is not backwords compatible (e.g. rename, remove, or move a column), you may risk some downtime or have some requests fail while the new version of your application is deployed.
For example, in *Fig. 2* below, deploying a change that moves a column from one table to another results in request failures from the time the migration is applied to when the previous version of the application is removed.

<p align="center">
    <img src="./imgs/diagrams/timeline-deployment-1.png" alt="timeline of application deployment" style="height: 350px;"/>
</p>

*Fig. 2: Original Deployment Timeline*

Previously, I had the attitude that failures during deployment were acceptable.
_I had 5% of requests fail for 5 minutes? Meh. As long as the new code is working as expected, I am good._
However, I wanted to deploy these type of changes without any failures because I worked with critical data and a 1% request failure rate was a _really_ big deal.
I quickly found [Refactoring Databases](https://martinfowler.com/books/refactoringDatabases.html) by Scott Ambler and Pramod Sadalage and was delighted to see it had similar principles to break down data model refactors into safe, manageable pieces.

Revisiting the example of moving a column from one table to another, the key is to keep the schema backwards compatible to allow for a smooth transition between different versions of the application and allow for application rollbacks.
You can do this in a couple of phases where the new column location and updated application logic is grouped into one deployment and the removal of the old column with a following deployment.
This prevents errors from schema misalignment while transitioning between application versions.

<p align="center">
    <img src="./imgs/diagrams/timeline-deployment-2.png" alt="timeline of clean application deployment" style="height: 350px;"/>
</p>

*Fig. 3: Refactored Deployment Timeline*

For destructive schema migrations (e.g., a change that would require renaming or removing a column), the refactoring procedure is as follows:

1. Phase 1: **Deprecate Columns**
    * Write a migration to add columns (if necessary).
        * When moving a column, you will also need to move data over to the new column and set up triggers to synchronize data between the columns.
    * If moving a column, then update the application to use the new column location. If removing a column, then update the application to stop using a column to be removed.
    * Deploy.
1. Phase 2: **Transition**
1. Phase 3: **Cleanup**
    * Write a migration that removes the previously used column.
    * Deploy.

Thanks for reading!
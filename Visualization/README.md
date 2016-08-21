# Creating a final visualization
### Step 1: Select an appropriate platform
While we had experience using a number of platforms for visualization (Tableau, Flask, etc) we ultimately chose R's `Shiny` platform due to it's flexibility and simplicity. 

Shiny is a powerful web application framework that allows for beautiful web applications to be built leveraging mostly R language + HTML, CSS and a modicum of Javascript. Once that decision was made, we settled on `Flexdashboard` which is a simplifcation of the Shiny framework itself that makes it extremely easy to format and layout graphs and add interactivity leveraging the Bootstrap framework. 

### Step 2: Visualize a Flexdashboard
Since we had created a number of exploratory visualizations in R to begin with, porting them to the Flexdashboard platform was relatively straightforward. 
- In order to add interactivity to our `ggplots`, we used the `plotly` library as a wrapper
- We added multiple UI elements that allows for interactive filtering -- each of our graphs is based on the same underlying data -- which, when filtered, updates everything simultaneously
- Finally, we decided on a layout that would be conducive to analysis: 
  -  On page 1, we present generalized stats about the tweets themselves
  -  On page 2, we look in depth at sentiment and offer the user the ability to drill down by various dimensions on our main unit of analysis: tweet sentiment

The code once finalized locally, is served from two locations:
-  We installed a Shiny Server on one of our nodes, P4, and exposed the dashboard here: http://192.155.215.11:3838/w251/
-  We also made sure to add some redundancy - because the usage of these machines is temporary, we uploaded the visualization to the platform shinyapps.io -- the viz will always be available here as well: https://gregce.shinyapps.io/tweet_viz/

**A note:** The file optimized_for_viz.Rda contains all the data, in an R specific compressed format, contained in the visualization. It is loaded when the viz is invoked and can be used locally if one is interested in modifying or running this viz locally

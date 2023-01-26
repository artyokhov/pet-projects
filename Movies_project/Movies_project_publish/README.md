<h1>Movies Industry Overview Project</h1>


<h2>Introduction</h2>

<p>The core aim of the project is to demonstrate the author's ability to analyse data via usage of the applied technologies.<br>
The data used for this project was collected from the few sources:<br>
<ul>
<li>Open data regarding global box office of movies is available on <a href="https://www.boxofficemojo.com/year/world/2022/">the BoxOffice Mojo by IMDb</a>. </li>

<li>Additional data about movies, including data about production budgets, available on <a href="https://www.kaggle.com/datasets/rounakbanik/the-movies-dataset?select=movies_metadata">Keggle</a>.</li>

<li>Official <a href="https://www.imdb.com/interfaces/">IMDb database</a>.</li>
</ul></p>

The goal of the project was to show the size of the industry, detaled by genres through decades, and also show leading movies and key persons of the undustry with their achievements.<br>
The data contains movies released between 1970 and 2023, but given that metrics will be aggregated by decades, movies released after 2019 are excluded from the processed data.


<h2>Technologies</h2>
<p>The first part of the dataset was collected from Mojo website using web scrapping using <b>Python, Beautiful Soup</b>.<br>
Data preparation was performed via <b>PostgreSQL</b> with preliminary database creation.<br>
Some of the calculations and visuals were prepared in <b>Tableau Public.</b></p>

<ul>

<li><h3><b>Python</b></h3></li>

<p>The code of Python script which has collected data from Mojo website is shown in the<b><i>'mojo_scrapping.ipynb'</b></i> file in the <b><i>'Scripts'</i></b> folder, whilst the script output is located into the <b><i>'full_box_office_data.csv'</b></i> file which is available in the <b><i>'Output'</b></i> folder.<br></p>


<li><h3><b>SQL</b></h3></li>

<p>SQL queries are shown in <b><i>'Movies_main_queries.sql'</b></i> file in the <b>'Scripts'</b> folder, whilst quries results are collected into the <b><i>'Titles_data.csv'</b></i> and the <b><i>'People_data.csv'</b></i> files which are available in the <b><i>'Output'</b></i> folder.<br></p>

<li><h3><b>Tableau Public</b></h3></li>

><i>Given that Tableau Public does not allow to connect directly to a database, the preprocessed raw data for Tableau importing was exported through SQL query from database to CSV (the <b><i>'Titles_data.csv'</b></i> and the <b><i>'People_data.csv'</b></i> files in the <b><i>'Output'</b></i> folder).</i>

For the convenience of examining, Tableau visual part is provided in <b><i>.twbx</b></i>, and <b><i>.pdf</b></i> (<b><i>'Tableau_viz'</b></i> folder).<br>
The same viz is also reachable through [the Tableau Public cloud](https://public.tableau.com/app/profile/artem5389/viz/Movies_project_16747515581980/Dashboard1?publish=yes).
</ul>




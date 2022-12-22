<h1>Australian Retailer Sales Data Analysis</h1>


<h2>Introduction</h2>

<p>The core aim of the project is to demonstrate the author's ability to analyse data via usage of the applied technologies.<br>
As a raw dataset the real retailer sales data was used.</p><br>


<h2>Technologies</h2>
<p>The dataset preparation was performed via <b>PostgreSQL</b> with preliminary database creation, as well as some calculations.<br>
Some of the same calculations together with complementary ones and visuals were prepared in <b>Tableau Public.</b></p><br><br>

<ul>
<li><h3>SQL</h3></li>

<p>SQL queries are shown in <b><i>'Australia_sales_main_queries.sql'</b></i> file in the core folder, whilst quries results are collected into the common <b><i>'Output_of_queries_1_to_12.xlsx'</b></i> file which is available in <b><i>'Queries_output'</b></i> folder.<br>
Each query in the <b><i>'Australia_sales_main_queries.sql'</b></i> file has a number which corellates with a number represented in the <b><i>'Output_of_queries_1_to_12.xlsx'</b></i> file.</p><br><br>

<li><h3>Tableau Public</h3></li>

><i>Given that Tableau Public does not allow to connect directly to a database, the preprocessed raw data for Tableau importing was exported through SQL query from database to CSV ('#13_Australia_retail_data.csv' file in the 'Queries_output' folder).</i><br><br>

<p>For the convenience of examining, Tableau visual part is provided in <b><i>.twbx, .pdf and web-shortcut</b></i> (<b><i>'Tableau_viz'</b></i> folder).\
The same viz is also reachable through [the Tableau Public cloud](https://public.tableau.com/app/profile/artem5389/viz/Retail_Sales_Data_Analysis/Story1?publish=yes>).</p><br></ul>

<h2>Sources</h2>
<p>There are 4 CSV-files in a raw data:
<ul>
<li>retail_sales.csv - main source of sales data.</li>
<li>retail_category.csv - product categories list with responsible buyers.</li>
<li>retail_manager.csv - list of managers with their responsibility areas.</li>
<li>retail_state.csv - specific data related to areas.</li></ul><br>

The project was inspired by [the article on Medium.com](https://medium.com/@amosadewuni/analyzing-a-retail-business-sales-data-in-postgresql-b3920422abc5).<br>




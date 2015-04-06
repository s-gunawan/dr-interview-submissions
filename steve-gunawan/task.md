# dr-interview-submissions
Interview submissions for Developer Relations Engineering team

====================================================

OAuth is authentication protocol that is used to grant application access to user's account, without requiring user to input their credential into the application itself.

An application provides a consumer key and shared secret to get a Request Token specific to the user from Twitter, then the application directs user to Twitter's Oauth login page using the newly obtained Request Token. Once user logs in successfully to approve OAuth, Twitter exchanges Request Token into Access Token that is used by the app along with Consumer Key to get Token Secret from Twitter. From this point onwards, the application is authorized to have access to Twitter using consumer key, consumer secret, access token, and token secret.

Oauth vs cookie
Cookies are local representation of user state after logging in, cookies may time out after period of inactivity or after their expiration dates and need to be renewed.
With OAuth, after the authentication completes, there is no state. Consumer key and access token are used in every call to the API, thus making a RESTful Web Services possible.

====================================================

Rate limiting is a mechanism to control the number of API calls that can be made within a certain period of time (15 mins block for Twitter). This is implemented by API/web service provider in order to scale up the API to serve larger user base and still provide acceptable quality of service.
For Twitter API, HTTP Headers returned by an API call contains the rate limit status/info for the user-application context.
Upon exceeding a rate limit, the application will get error 429 (Rate Limit Exceeded) returned by the API response.

====================================================

From my experience working in SAS for the last few years, I have become a strong supporter of SAS platform. To process data in SAS, one can use both SAS language or SQL. Let me highlight 6 of my most favorite features of SAS:


1. The DATA step, which is probably the most commonly used function in SAS, iterates once for each record/observation that is being created. It's basically an implied loop without the need to code a loop, which makes the code easier to read.

For example, let's say there is a price dataset with two columns, date and price, we can easily find the daily price changes by using the data step and lag & diff functions. Note that there is no loop or row number needed in order to perform this operation for all of the data.

data price_delta;
  set price;	/* read source table price */
  prev_price = lag(price);	/* reads price variable from previous row */
  diff_from_prev_price = diff(price);	/* calculates the difference of price from current row with price from previous row */
run;


2. IFC & IFN, which is a conditional one-line IF statement. It works like a shortcut for the CASE-WHEN-END statements in typical SQL syntax, if the condition is about a binary selection. The IFC function deals with character variables, while the IFN function is for numbers.

data final_grades;
  set grades;	/* read source table grades */
  performance = ifc(grade>80, 'Pass', 'Needs Improvement');	/* one line if statement to determine performance */
run;


3. Monotonic, which is a SAS SQL syntax to get the observation/row number for a dataset. Can be used to easily create an id column when needed.

proc sql;
  select *, monotonic() as row_id	/* row_id will be 1,2,3,etc */
  from price;
quit;


4. Calculated: can be used in a where filter to refer to a calculated value without needing to rewrite the calculation step.

proc sql;
  create table as students_who_pass ass
  select *, (midterm_grade + 2*final_exam_grade + 2*paper_grade)/5 as final_grade
  from grade
  where calculated final_grade > 80;	/* simply refer to result of calculation in where statement using the calculated keyword */
quit;


5. SAS Enterprise Guide, which is the modern point & click Windows UI for SAS, has the ability to support a custom-written add-in. This allows software developer to extend the power of point & click interface offered by SAS and deploy it to a larger user base within the organization. In one of my previous project, I built a pricing application that can be loaded within SAS Enterprise Guide, utilizing the power of both .Net Windows form design and SAS language. The user interface has the ease of Windows point & click interface, but also supports SAS language in the background that does the complex processing of the pricing data.


6. Passionate SAS local user groups/tech community existence in almost everywhere. You can usually find groups of passionate SAS users within the region and they are often supported by SAS. Most of them would have a quarterly meeting or annual conference, which are driven and organized mostly by the volunteers from the user groups. Anybody can submit a paper on a topic they know well and if accepted, he/she will present in the conference. It's a great networking event where one can meet and learn from the veterans SAS users as well as getting the latest update from SAS Institute.
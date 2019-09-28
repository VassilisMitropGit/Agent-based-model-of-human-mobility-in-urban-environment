model agent_based_mode_missing_person


global {
	file shape_file_buildings <- file("../includes/building.shp"); //load buildings file
	file shape_file_roads <- file("../includes/road.shp"); //load road file
	
	geometry shape <- envelope(envelope(shape_file_buildings) + envelope(shape_file_roads)); //create the geometry of the simulation using the building and road shape file
	
	float step <- 10 #mn; //every step is defined as 10 minutes
	
	int nb_people <- 100; //number of people in the simulation
	int nb_missing <- 1; //number of missing people (It's will always be 1 in this simulation)
	int missing -> {length(missing_person)};
	
	int current_hour update: (time / #hour) mod 24; //the current hour of the simulation
	
	//the following are variables conserning the times that people go and leave work respectively
	int min_work_start <- 7;
	int max_work_start <- 9;
	int min_work_end <- 16; 
	int max_work_end <- 18; 
	
	//tho following are variables conserning the speed that the agents are traveling. It is in km per hour
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	
	//tho following are variables conserning the speed that the missing person agent will be traveling. It is in km per hour
	float min_speed_missing <- 1.0 #km / #h;
	float max_speed_missing <- 5.0 #km / #h; 
	
	graph the_graph; //initialize the graph that the agents will be moving on
	
	list missing_agents -> missing_person.population;
	agent the_missing_agent -> missing_agents at 0;

	
	init {
		
		//create the buildings and road from the imported files
		create building from: shape_file_buildings;
		create road from: shape_file_roads ;
		
		the_graph <- as_edge_graph(road); //create the graph initialized above as an edge graph
		
		//the function that creates the people agents
		create people number: nb_people {
			
			//define the speed, start and end work time that each agent will have.
			//these values are random so it will be different in each simulation
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			
			//define a living and a working place for each agent from the imported buildings
			living_place <- one_of(building) ;
			working_place <- one_of(building) ;
			
			objective <- "resting"; //each agent will begin resting, until it's time for him/her to go to work
			
			location <- any_location_in (living_place); //the agents home is his/her starting location
			
		}
		
		//the function that creates the missing person agent
		create missing_person number: nb_missing {
			
			speed <- min_speed + rnd (max_speed - min_speed) ;
			
			//these are not used for the missing person agent
			/*
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			*/
			
			
			//the following are similar to the normal agents parameters
			living_place <- one_of(building) ;
			objective <- "running";
			location <- any_location_in (living_place); 
			
			
		}
	}
	
	//the following stops the simulation when the missing person is found
	reflex stop_simulation when: missing = 0 {
		do pause;
	}
}


//define the building species
species building {
	string type; 
	rgb color <- #gray  ; //the color of each building
	
	aspect base {
		draw shape color: color ;
	}
}

//define the road species
species road  {
	rgb color <- #black ; //the color of each road
	aspect base {
		draw shape color: color ;
	}
}


//define the missing_person species
species missing_person skills:[moving] {
	rgb color <- #red;
	
	building living_place <- nil ;

	string objective <- "running" ; 
	point the_target <- nil ;
		
	list people_nearby <- agents_at_distance(1); // people_nearby equals all the agents (excluding the caller) which distance to the caller is lower than 20
	
	int nb_of_agents_nearby -> {length(people_nearby)};
	
	//this reflex sets the variable "found" to true when the list "people_nearby" has contents.
	//If "people_nearby" has items in it, that means that there are agents nearby the missing person
	reflex is_found when: length(people_nearby) >= 1{
		//do die;
	}
	
	//this reflex sets the target of the missing person to a random building
	reflex run when: objective = "running"{
		the_target <- (one_of(the_graph.vertices));
		people_nearby <- agents_at_distance(1);
	}
		
	//this reflex defines how the missing person moves 
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	//the visualisation of the missing person on the graph
	aspect base {
		draw circle(10) color: color border: #black;
	}
	
}


//define the people species
species people skills:[moving] {
	
	rgb color <- #yellow ;
	
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work ;
	int end_work  ;
	
	string objective ; 
	point the_target <- nil ;
		
	//this reflex sets the target when it's time to work and changes the objective of the agent to working
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	//this reflex sets the target when it's time to go home and changes the objective of the agent to resting
	reflex time_to_go_home when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	
	
	//this reflex defines how the people agent moves  
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	//the visualisation of the missing person on the graph
	aspect base {
		draw circle(10) color: color border: #black;
	}
}


experiment find_missing_person type: gui {
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	
	parameter "Number of people agents" var: nb_people category: "People" ;
	
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    
	parameter "minimum speed" var: min_speed category: "People" min: 0.1 #km/#h ;
	parameter "maximum speed" var: max_speed category: "People" max: 50 #km/#h;
	
	parameter "minimum speed for missing person" var: min_speed_missing category: "People" min: 0.1 #km/#h ;
	parameter "maximum speed for missing person" var: max_speed_missing category: "People" max: 50 #km/#h;
	
	output {
		
		display city_display type: opengl {
			species building aspect: base refresh: false;
			species road aspect: base refresh: false;
			species people aspect: base ;
			species missing_person aspect: base ;
		}
		
		display chart_display refresh:every(10#cycles) {
			chart "People Objective" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
                data "Working" value: people count (each.objective="working") color: #magenta ;
                data "Resting" value: people count (each.objective="resting") color: #blue ;
            }
            
        }
        display chart refresh:every(10#cycles) {
            chart "Number of people nearby the missing person" type: series {
                data "Number of agents nearby" value: the_missing_agent get('nb_of_agents_nearby')  color: #red;
            }
        }
        
	}
}
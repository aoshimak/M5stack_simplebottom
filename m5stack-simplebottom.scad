// M5stack simple bottom case forked from:
// https://github.com/xoseperez/m5stack-rfm95/blob/master/enclosure/m5stack-rfm95.scad
//

// -------------------------------------------------
// Configuration
// -------------------------------------------------

// switch the pattern what you make:
// bottom case = 1, bottom case without inside screw hole = 2
// middle case = 3
pattern = 2;

// thick of the base plate (mm)
base_height = 3;   

// screw base height (over the base plate) (mm)
screwbase_height = 3 ;

// wall_height (mm): need to set over screwbase_height
wall_height = 10; 

// if you make middle case, please set this height.
middle_height = 20;

// -------------------------------------------------
// Definition of size
// -------------------------------------------------
outer_size = 54.0;
outer_corner = 5.0;

wall_width = 1.8;  // default 1.7

tab_width = 0.6;   // default 0.7
tab_height = 1.0;

hole_height = 5.0;

inner_size = outer_size - 2 * wall_width;
inner_corner_diameter = outer_corner - wall_width;

// -------------------------------------------------
// Settings
// -------------------------------------------------

$fn = 50;

// -------------------------------------------------
// Function
// -------------------------------------------------

// wall module (function)
module wall(outer, width, corner) {

    inner = outer - 2 * width;
    inner_corner = corner - width;

    difference() {

        minkowski() {
            square(outer - 2 * corner, true);
            circle(corner);
        }

        minkowski() {
            square(inner - 2 * inner_corner, true);
            circle(inner_corner);
        }
    }
}

// -------------------------------------------------
// Modules
// -------------------------------------------------

// makeing wall with wall module
module walls() {
    wall(outer_size, wall_width, outer_corner);
}

// makeing tab with wall module
module tabs() {
    outer = outer_size + (tab_width - wall_width) * 2;
    corner = outer_corner + (tab_width - wall_width);
    difference() {
        wall(outer, tab_width, corner);
		
		// cut tabs with square
        square([32,outer_size], true);
        square([outer_size,39], true);
    }
}

// making outer screw hole 
module screw() {
    union(){
        //screw head space for M3, h=3.5
        cylinder(r=6.4/2, h=3.5);
        //screw core hole for M3, h=total height of body
        cylinder(r=3.2/2, h=base_height + wall_height);
        
        // very little bar sank into the base,
		// to connect between the outer path and  outline of hole (for FDM printers)
        translate([0,-0.1,0])
        cube ([10,0.2,0.4], center=false);        
    }
}

// multiply 4 screw holes
// rotate 45 and 135 degree for outline connection

module screw_unit(){
    union() {
        translate([22,22])
        rotate (45)
        screw();

        translate([22,-22]) 
        rotate (-45)
        screw();

        translate([-22,22])
        rotate (135)
        screw();

        translate([-22,-22]) 
        rotate (-135)
        screw();
    }
}

// overhang support for screw hole
// 6 small cones set into the screw box after build up body.
module scsupport() {
    union(){
        for ( i = [0:60:300]) 
        rotate(i)
        translate([2.2,0,0])
        cylinder(r1=0.7, r2=0.3, h=3.5);
    }
}

// multiply screw hole support
module scsupport_unit(){
    union() {
        translate([22,-22]) scsupport();
        translate([-22,-22]) scsupport();
        translate([-22,22]) scsupport();
        translate([22,22]) scsupport();
    }
}

// make screw base inside case. 
module scbase(){
    cylinder(r=4, h=screwbase_height + base_height);
}

// mlutiply screw base
module scbase_unit(){
    union() {
        translate([22,-22]) scbase();
        translate([-22,-22]) scbase();
        translate([-22,22]) scbase();
        translate([22,22]) scbase();
    }
}

// building base plate
module baseplate() {
    minkowski() {
        square(outer_size - 2 * outer_corner, true);
        circle(outer_corner);
    }
}

// inside screw pole for circuit plate
module hole() {
    translate([18,22]) {
        difference() {
            union() {
                circle(3.7/2);
                translate([-3.7/2,0]) square([3.7,5]);
            }
            circle(2.0/2);
        }
    }
}

// multiply screw pole with mirror
module holes() {
    hole();
    mirror([1,0,0]) hole();
    mirror([0,1,0]) {
        hole();
        mirror([1,0,0]) hole();
    }
}

// -------------------------------------------------
// Build up
// -------------------------------------------------

// bottom case
module bottom_layer() {
    
    // diff (whole body) - (outer screw)
    difference() {

        // unite whole body:
        // baseplate + wall + screw pole + tab + screw base
        union() {
            
            // render base plate
            linear_extrude(base_height) 
            baseplate();
    
            // render wall and screw pole over the base plate
            // (over base plate part)
            translate([0,0,base_height]) {
                    
                // render wall itself
                  linear_extrude(wall_height) walls();
                                
                // render inner screw pole
                // translate([0,0,wall_height-hole_height]) {
                //     linear_extrude(hole_height) holes();
                // }
                
                //render tabs
                translate([0,0,wall_height]) {
                    linear_extrude(tab_height) tabs();
                }
    
            }
            //render screw hole base
            translate([0,0,0]) {
                scbase_unit();
            }
        }


    // open outer screw hole
    screw_unit();
    }

}

// middle layer case
module middle_layer() {

    // diff (middle layer case) - (lower tabs for connect)
    difference() {
        
        // build up middle layer case
        union() {
            
            // wall
            linear_extrude(middle_height)
            walls();
            
            // inside screw pole
            // translate([0,0,middle_height-hole_height]) {
            //    linear_extrude(hole_height) holes();
            //}
            
            // upper tabs
            translate([0,0,middle_height]) {
                linear_extrude(tab_height) 
                tabs();
            }
        }
        
        // making groove for connection
        linear_extrude(tab_height) 
        tabs();
    }
}

// -------------------------------------------------
// Output object
// -------------------------------------------------

if (pattern == 1)
{
    bottom_layer();
    
    //inside screw pole
    translate([0,0,wall_height - hole_height]) {
        linear_extrude(hole_height) holes();
    }

    // add support into the outer screw hole (for FDM printers)
    scsupport_unit();
}

else if (pattern == 2)
{
    bottom_layer();
    
    // add support into the outer screw hole (for FDM printers)
    scsupport_unit();
}

else if (pattern == 3)
{
    // translate ([0,100,0])
    middle_layer();
    
    //inside screw pole
    translate([0,0,middle_height-hole_height]) {
        linear_extrude(hole_height) holes();
    }

}

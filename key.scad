use<gears.scad>;
use<MCAD/2Dshapes.scad>;

// $fa=10;
// $fs=.1;
// $fr=200;

// Low Res
//  $fs=2;
$fa=5; 
$fs=0.01;

ASSEMBLED = true;

// Module
M = 1;
// Ratio between the x/y from the Somsky gear solver and our coordinates
XY_SCALE = 0.5;

// Radius of axle holes
AXLE_R = 0.4;

// Height of each layer
H = 4;

// Pressure angle
W = 25;

RING_GEAR_TEETH = 53;
RING_GEAR_D = 70;
CARRIER_INSET = 6;

/**
Taken from: https://tomas.rokicki.com/somsky.html

offset = 18.07266195954014 mingap=5.558356361320534
D: r=53 x=0 y=0
A: r=26 x=0 y=-18.07266195954014
B: r=11 x=-36.951605920044734 y=-19.964438883417564
C: r=8 x=30.509585009171065 y=-33.078168367794554
B': r=16 x=36.951605920044734 y=1.8917769238774214
C': r=19 x=-30.509585009171065 y=15.005506408254414
**/

GEARS = [
  [26, 0, -18.073],
  [11, -36.95, -19.96],
  [8, 30.51, -33.078],
  [16, 36.95, 1.89],
  [19, -30.51, 15.01]
];

function gear2dOffset(i, acc = 0) =
  i == 0
    ? acc
    : gear2dOffset(i - 1, acc + (0.5 * GEARS[i - 1][0] + 0.5 * GEARS[i][0]) + 3);

module ring() {
  // Ring Gear
  ring2D(M, RING_GEAR_TEETH, D=RING_GEAR_D, w=W);
}

module gears() {
  for(i=[0:len(GEARS) - 1]) {
    gear = GEARS[i];

    pos = ASSEMBLED
      ? [gear[1] * XY_SCALE, gear[2] * XY_SCALE]
      : [gear2dOffset(i), -60];

    translate(pos) {
      difference() {
        color([.3, 0, 0]) {
          gear2D(M, gear[0], w=W);
        }
        circle(r=AXLE_R);
      }
    }
  }
}

module carrierHolder() {
  difference() {
    circle(d=RING_GEAR_D);
    circle(d=RING_GEAR_D - CARRIER_INSET + 0.25);
  }
}

module carrier() {
  difference() {
    union() {
      // Ring around the outside that sits just under the ring gear’s teeth.
      difference() {
        circle(d=RING_GEAR_D - CARRIER_INSET);
        circle(r=RING_GEAR_TEETH / 2 + 1.5);
      }

      // Full circle, minus an arc centered on the sun gear.
      difference() {
        circle(d=RING_GEAR_D - CARRIER_INSET);
        translate([GEARS[0][1] * XY_SCALE, GEARS[0][2] * XY_SCALE])
          rotate([0, 0, 25]) {
            donutSlice(3, 100, 0, 110);
          }
        }

      // Put back in circles that will be hidden by the gears' bodies.
      for (gear=GEARS) {
        translate([gear[1] * XY_SCALE, gear[2] * XY_SCALE]) {
          circle(d=gear[0] - 2);
        }
      }

      // Add a full half circle so we know that we can cover the whole
      // colored background.
      difference() {
        circle(d=RING_GEAR_D - CARRIER_INSET);
        rotate([0, 0, -10]) {
          donutSlice(0, 100, 0, 180);
        }
      }
    }

    // Removes the hole for the gear axles
    for (gear=GEARS) {
      translate([gear[1] * XY_SCALE, gear[2] * XY_SCALE]) {
        circle(r=AXLE_R);
      }
    }
  }
}

module back() {
  circle(d=RING_GEAR_D);
}

module driver() {
  DRIVER_INDEX= 1;

  // Driver gear
  translate(ASSEMBLED
      ? [GEARS[DRIVER_INDEX][1] * XY_SCALE,
        GEARS[DRIVER_INDEX][2] * XY_SCALE] : [100, -60]) {

    difference() {
      union() {
        difference() {
          gear2D(M * 1.45, 20);
          circle(d=20);
        }
        circle(d=8);

        for (ang = [0:60:300]) {
          rotate([0, 0, ang]) {
            square([3, 10]);
          }
        }
      }

      circle(r=AXLE_R);
    }
  }
}

if (ASSEMBLED) {
  color([.3, .3, .3]) {
    union() {
      linear_extrude(H) {
        ring();
      }

      translate([0, 0, -H]) {
        linear_extrude(H) {
          carrierHolder();
        }
      }

      translate([0, 0, -2 * H]) {
        linear_extrude(H) {
          back();
        }
      }
    }
  }

  color([.7, .8, .7]) {
    linear_extrude(H) {
      gears();
    }
  }

  translate([0, 0, H]) {
    color([.3, .3, .8]) {
      linear_extrude(H) {
        driver();
      }
    }
  }

  translate([0, 0, -H]) {
    color([.3, .6, .4]) {
      linear_extrude(H) {
        carrier();
      }
    }
  }

} else {
  ring();
  gears();
  driver();
  translate([75, 0, 0]) {
    carrier();
  }
  translate([150, 0, 0]) {
    carrierHolder();
  }
  translate([225, 0, 0]) {
    back();
  }
}

// 2D adaptation of the gears.scad ring algorithm
module ring2D(m = 1, z = 10, x = 0, h = 4, w = 20, D = 0, clearance = -.1) 
{
   D_= D==0 ? m*(z+x+4):D; 
   difference()
   {
    circle(r = D_/2);
		gear2D(m, z, x, w, clearance = clearance); 
	}
}

// TRACK-2 DRIVETRAIN SOLIDS — the gear train + cam drum + Geneva (positions verified by check_drive/check_cam)
// =============================================================================
// One central INPUT shaft carries: a CAM DRUM (continuous -> dish-rise + seg-drop + magnet-lift cam
// grooves) and a GENEVA DRIVER. The Geneva turns the SUN gear intermittently (only during the middle
// window) -> the SUN drives a PLANET on each of the 5 divider posts (4 ring + 1 apex via an IDLER) so
// every divider turns pi. Hollow sun centre = the 2-9 lane. Gears are trapezoidal here (clean, meshes
// at the verified centres) — swap for true involute at print-prep.
//   PART in: gears | sun | planet | idler | drum | geneva | all
SCALE=20/18; R=50*SCALE; N=11; apexR=R+24*SCALE;
m=1.5; Ns=60; Np=11; Ni=11;            // module + teeth (from check_drive)
Rs=Ns*m/2; Rp=Np*m/2; Ri=Ni*m/2;       // pitch radii 45 / 8.25 / 8.25
GZ=-9; gh=4;                            // gear-layer z and thickness (below the balls)
function angleOf(k)=-90+(k-1)*(360/N);
function P(k)= k==0?[0,apexR]:[R*cos(angleOf(k)),-R*sin(angleOf(k))];
function mid(i,j)=[(P(i)[0]+P(j)[0])/2,(P(i)[1]+P(j)[1])/2];
function vlen(v)=sqrt(v[0]*v[0]+v[1]*v[1]);
RINGP=[[3,4],[5,6],[7,8],[10,11]];
apex=mid(0,1); ra=vlen(apex);
// idler at the circle-circle intersection (mirror check_drive)
r1=Rs+Ri; r2=Ri+Rp; _a=(ra*ra+r1*r1-r2*r2)/(2*ra); _h=sqrt(r1*r1-_a*_a);
idler=[(apex[0]/ra)*_a-(apex[1]/ra)*_h, (apex[1]/ra)*_a+(apex[0]/ra)*_h];

function ipt(r,a)=[r*cos(a),r*sin(a)];
module gear(n, thick=gh, bore=2.6) {     // trapezoidal-tooth spur gear (meshes at pitch r = m*n/2)
    pr=m*n/2; ra_=pr+0.9*m; rf=pr-1.15*m; ang=360/n;
    linear_extrude(thick, convexity=6) difference() {
        union() {
            circle(r=rf, $fn=max(40,3*n));
            for(i=[0:n-1]) rotate([0,0,i*ang]) polygon([
                ipt(rf,-ang*0.30), ipt(pr,-ang*0.20), ipt(ra_,-ang*0.10),
                ipt(ra_, ang*0.10), ipt(pr, ang*0.20), ipt(rf, ang*0.30) ]);
        }
        if(bore>0) circle(r=bore, $fn=28);
    }
}

module gear_train() {
    // SUN — hollow (the 2-9 lane crosses the open centre)
    translate([0,0,GZ]) difference() { gear(Ns, gh, bore=0); cylinder(h=gh*3,center=true, r=Rs-4*m, $fn=120); }
    color([0.80,0.55,0.30]) for(pr=RINGP){ M=mid(pr[0],pr[1]); translate([M[0],M[1],GZ]) gear(Np); }   // 4 ring planets
    color([0.85,0.45,0.30]) translate([apex[0],apex[1],GZ]) gear(Np);                                   // apex planet
    color([0.55,0.70,0.85]) translate([idler[0],idler[1],GZ]) gear(Ni);                                 // idler
}

// ---- CAM DRUM: central cylinder on the input shaft, with cam grooves for the lifts ----
drum_r=10; drum_z0=GZ-16; drum_z1=GZ-1;
module cam_groove(zc, depth, lobe){        // a ring groove whose floor rises/falls = the cam profile
    rotate_extrude($fn=120) translate([drum_r-depth/2,zc]) square([depth, 2.2], center=true);
    // a lobe (raised section) approximating the dwell/lift — schematic
    for(a=[0:5:lobe]) rotate([0,0,a]) translate([drum_r-depth,zc-1.1,0]) rotate([90,0,90]) linear_extrude(drum_r*0.18) polygon([[0,0],[2.2,0],[2.2,1.5]]);
}
module cam_drum(){
    difference(){
        cylinder(h=drum_z1-drum_z0, r=drum_r, $fn=80);
        translate([0,0,drum_z0]) cam_groove(4, 2.5, 120);    // dish-rise track
        translate([0,0,drum_z0]) cam_groove(9, 2.5, 90);     // seg-drop track
        translate([0,0,drum_z0]) cam_groove(13,2.5, 60);     // 2-9 magnet-lift track
        translate([0,0,-1]) cylinder(h=drum_z1-drum_z0+2, r=2.6, $fn=24);   // shaft bore
    }
}

// ---- GENEVA: continuous driver (pin + lock arc) turns the slotted wheel (= sun) intermittently ----
module geneva_wheel(slots=6, rw=14, th=4){     // the SUN's intermittent wheel (drives the divider train)
    linear_extrude(th) difference(){
        circle(r=rw, $fn=80);
        for(i=[0:slots-1]) rotate([0,0,i*360/slots]) translate([rw,0]) square([rw*0.7, 3.2], center=true);  // radial slots
        circle(r=2.6,$fn=24);
    }
}
module geneva_driver(rw=14, th=4){
    rd=rw*0.72;
    linear_extrude(th){ circle(r=rd*0.55,$fn=48); translate([rd,0]) circle(r=1.6,$fn=20); }   // disc + drive pin
    translate([0,0,-0.1]) linear_extrude(th+0.2) difference(){ circle(r=rd*0.62,$fn=60);     // locking arc
        rotate([0,0,-30]) polygon([[0,0],[rd,0],ipt(rd,60)]); }
}

// ---------------- dispatch ----------------
PART="all";
if      (PART=="gears")  gear_train();
else if (PART=="sun")    difference(){ gear(Ns, gh, bore=0); cylinder(h=gh*3,center=true,r=Rs-4*m,$fn=120); }
else if (PART=="planet") gear(Np);
else if (PART=="idler")  gear(Ni);
else if (PART=="drum")   cam_drum();
else if (PART=="geneva") { geneva_wheel(); translate([14+9,0,0]) geneva_driver(); }
else {                                            // assembled preview
    gear_train();
    color([0.5,0.5,0.6]) translate([0,0,drum_z0]) cam_drum();
}

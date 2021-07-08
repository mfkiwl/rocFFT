import graph;
import utils;
import stats;

texpreamble("\usepackage{bm}");

size(400, 300, IgnoreAspect);

// Input data:
string filenames = "";
string secondary_filenames = "";
string legendlist = "";

// Graph formatting
bool doyticks = true;
string xlabel = "Problem size N";
string ylabel = "Time [s]";

string primaryaxis = "time";
string secondaryaxis = "speedup";

usersetting();

if(primaryaxis == "gflops") {
    ylabel = "GFLOP/s";
}

write("filenames:\"", filenames+"\"");
if(filenames == "") {
    filenames = getstring("filenames");
}
    
if (legendlist == "") {
    legendlist = filenames;
}

bool myleg = ((legendlist == "") ? false : true);
string[] legends = set_legends(legendlist);
for (int i = 0; i < legends.length; ++i) {
  legends[i] = texify(legends[i]);
}
  
// Create an array from a comma-separated string
string[] listfromcsv(string input)
{
    string list[] = new string[];
    int n = -1;
    bool flag = true;
    int lastpos;
    while(flag) {
        ++n;
        int pos = find(input, ",", lastpos);
        string found;
        if(lastpos == -1) {
            flag = false;
            found = "";
        }
        found = substr(input, lastpos, pos - lastpos);
        if(flag) {
            list.push(found);
            lastpos = pos > 0 ? pos + 1 : -1;
        }
    }
    return list;
}

string[] testlist = listfromcsv(filenames);

// Data containers:
pair[][] xyval = new real[testlist.length][];
pair[][] ylowhigh = new real[testlist.length][];
real xmax = 0.0;
real xmin = inf;
real ymax = 0.0;
real ymin = inf;


// Read the data from the output files generated by alltime.py.
void readfiles(string[] filelist, pair[][] xyval, pair[][] ylowhigh, bool bounds)
{
    for(int n = 0; n < filelist.length; ++n)
    {
        string filename = filelist[n];
        write(filename);
        bool moretoread = true;
        file fin = input(filename);
        while(moretoread) {
            real xval = fin; // x-length
            if(eof(fin)) {
                moretoread = false;
                break;
            }
            real yval = fin; // Number of data points
            xyval[n].push((xval, yval));
            xmax = max(xmax, xval);
            xmin = min(xmin, xval);
            ymax = max(ymax, yval);
            ymin = min(ymin, yval);

            if(bounds)
            {
                real ylow = fin;
                real yhigh = fin;
                ylowhigh[n].push((ylow, yhigh));
            }
        }
    }
}

readfiles(testlist, xyval, ylowhigh, true);

bool xlog = true;
if(xmax / xmin < 10) {
    xlog = false;
}
bool ylog = true;
if(ymax / ymin < 10) {
    ylog = false;
}
scale(xlog ? Log : Linear, ylog ? Log : Linear);


// Plot the primary graph:
for(int n = 0; n < xyval.length; ++n)
{
    pen graphpen = Pen(n);
    if(n == 2) {
        graphpen = darkgreen;
    }
    string legend = myleg ? legends[n] : texify(testlist[n]);
    marker mark = marker(scale(0.5mm) * unitcircle, Draw(graphpen + solid));

    // Compute the error bars:
    pair[] dp;
    pair[] dm;
    for(int i = 0; i < xyval[n].length; ++i) {
        dp.push((0, xyval[n][i].y - ylowhigh[n][i].x));
        dm.push((0, xyval[n][i].y - ylowhigh[n][i].y));
    }
    errorbars(xyval[n], dp, dm, graphpen);
    
    // Actualy plot things:
    draw(graph(xyval[n]), graphpen, legend, mark);

}

xaxis(xlabel, BottomTop, LeftTicks);

if(doyticks)
{
    yaxis(ylabel, (secondaryaxis != "") ? Left : LeftRight,RightTicks);
}
else
{
    yaxis(ylabel,LeftRight);
}

attach(legend(),point(plain.E),(((secondaryaxis != ""))
                                ? 60*plain.E + 40 *plain.N
                                : 20*plain.E)  );


if(secondary_filenames != "")
{
    string[] second_list = listfromcsv(secondary_filenames);
    
    pair[][] xyval = new real[second_list.length][];
    pair[][] ylowhigh = new real[second_list.length][];

    bool interval = true;
    
    // FIXME: speedup has error bounds, so we should read it, but
    // p-vals does not.
    readfiles(second_list, xyval, ylowhigh, interval); 

    picture secondarypic = secondaryY(new void(picture pic) {
            int penidx = testlist.length;

            scale(pic, xlog ? Log : Linear, Linear);
            
            for(int n = 0; n < xyval.length; ++n)
            {
                pen graphpen = Pen(penidx + n);
                if(penidx + n == 2) {
                    graphpen = darkgreen;
                }
                graphpen += dashed;
                
                guide g = scale(0.5mm) * unitcircle;
                marker mark = marker(g, Draw(graphpen + solid));
                        
                if(interval)
                {
                    // Compute the error bars:
                    pair[] dp;
                    pair[] dm;
                    for(int i = 0; i < xyval[n].length; ++i) {
                        dp.push((0, xyval[n][i].y - ylowhigh[n][i].x));
                        dm.push((0, xyval[n][i].y - ylowhigh[n][i].y));
                    }
                    
                    errorbars(pic, xyval[n], dp, dm, graphpen);
                }
                draw(pic,graph(pic, xyval[n]), graphpen, legends[n] + " vs " + legends[n+1],mark);
            }

            yaxis(pic, secondaryaxis, Right, black, LeftTicks);
            attach(legend(pic), point(plain.E), 60*plain.E - 40 *plain.N  );
        });
    add(secondarypic);
}

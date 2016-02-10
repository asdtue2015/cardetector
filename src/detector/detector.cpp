#include <iostream>
#include <fstream>
#include <string>
#include <time.h>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <stdexcept>
#include <stdexcept>
#include "opencv2/gpu/gpu.hpp"
#include "opencv2/highgui/highgui.hpp"

using namespace std;
using namespace cv;



bool help_showed = false;


class Args
{
public:
    Args();
    static Args read(int argc, char** argv);

    string src;

    bool src_is_video;
    bool src_is_camera;

    int camera_id;

    bool write_video;
    string dst_video;
    double dst_video_fps;


    bool make_gray;

    bool resize_src;
    int width, height;

    double scale;
    int nlevels;
    int gr_threshold;

    double hit_threshold;
    bool hit_threshold_auto;

    int win_width;
    int win_stride_width, win_stride_height;

    bool gamma_corr;
};


class App
{
public:
    App(const Args& s);
    void run();

    void handleKey(char key);

    void hogWorkBegin();
    void hogWorkEnd();
    string hogWorkFps() const;



    void workBegin();
    void workEnd();
    string workFps() const;

    string message() const;

private:
    App operator=(App&);

    Args args;
    bool running;

    bool use_gpu;
    bool make_gray;

    double scale;
    int gr_threshold;
    int nlevels;
    double hit_threshold;
    bool gamma_corr;

    int64 hog_work_begin;
    double hog_work_fps;

    int64 work_begin;
    double work_fps;
};

static void printHelp()
{
    cout << "Histogram of Oriented Gradients descriptor and detector sample.\n"
         << "\nUsage: hog_gpu\n"
         << "  (<image>|--video <vide>|--camera <camera_id>) # frames source\n"
         << "  [--make_gray <true/false>] # convert image to gray one or not\n"
         << "  [--resize_src <true/false>] # do resize of the source image or not\n"
         << "  [--width <int>] # resized image width\n"
         << "  [--height <int>] # resized image height\n"
         << "  [--hit_threshold <double>] # classifying plane distance threshold (0.0 usually)\n"
         << "  [--scale <double>] # HOG window scale factor\n"
         << "  [--nlevels <int>] # max number of HOG window scales\n"
         << "  [--win_width <int>] # width of the window (48 or 64)\n"
         << "  [--win_stride_width <int>] # distance by OX axis between neighbour wins\n"
         << "  [--win_stride_height <int>] # distance by OY axis between neighbour wins\n"
         << "  [--gr_threshold <int>] # merging similar rects constant\n"
         << "  [--gamma_correct <int>] # do gamma correction or not\n"
         << "  [--write_video <bool>] # write video or not\n"
         << "  [--dst_video <path>] # output video path\n"
         << "  [--dst_video_fps <double>] # output video fps\n";
    help_showed = true;
}


//Creating .txt with respect to image's name
 void txtGenerator (int argc, char** argv)
{

// assign path's name to a string
string filename="";
filename = argv[1];

// get the name of the input image

unsigned firstpoint =filename.find_last_of("/");
unsigned lastpoint = filename.find_last_of(".");

string name = filename.substr(firstpoint+1, lastpoint-firstpoint-1);

std::cout << "Txt name: " <<name<<'\n';

// assign the name of the input as name of our file
  ofstream myfile;
// specify the extension of our file
  name += ".txt";
// create the .txt
  myfile.open (name.c_str() );
// write data inside the .txt
  myfile << "Vincent.\n";
  myfile << "Hazem.\n";
  myfile << "Andreas.\n";
  myfile << "Zhengyu.\n";
  myfile << "Lazaros.\n";
// close the .txt

  myfile.close();

// Here it ends the .txt coding
exit(0);
return;}


String detector_out(Rect* r){
        int x1;
        int x2;
        int y1;
        int y2;
        string txt_out_string;
        cout<<" r "<<*r<<endl;
        cout<<" x "<<r->x<<endl;
        cout<<" y "<<r->y<<endl;
        cout<<" w "<<r->width<<endl;
        cout<<" h "<<r->height<<endl;
        x1=r->x;
        y1=r->y;
        x2=(x1+r->width);
        y2=(y1+r->height);
        txt_out_string = "NotCar -1 -1 -10 "+to_string(x1)+" "+to_string(y1)+" "+to_string(x2)+" "+to_string(y2)+" -1 -1 -1 -1000 -1000 -1000 -10";
        cout<<txt_out_string<<endl;
        return txt_out_string;
}


int main(int argc, char** argv)
{


    try
    {
        if (argc < 2)
            printHelp(); // in case not enough inputs
        Args args = Args::read(argc, argv);
        if (help_showed)
            return -1;
        App app(args);
        app.run();
    }
    catch (const Exception& e) { return cout << "error: "  << e.what() << endl, 1; }
    catch (const exception& e) { return cout << "error: "  << e.what() << endl, 1; }
    catch(...) { return cout << "unknown exception" << endl, 1; }
    return 0;
}

Args::Args()
{
    src_is_video = false;
    src_is_camera = false;
    camera_id = 0;

    write_video = false;
    dst_video_fps = 24.;

    make_gray = false;


    resize_src = false;
    width = 640;
    height = 480;

    scale = 1.12; // "optimal" for KITTI dataset
    nlevels = 13;
    gr_threshold = 1;
    hit_threshold = 1.4;
    hit_threshold_auto = true;

    win_width = 64;
    win_stride_width = 8;
    win_stride_height = 8;
    gamma_corr = true;
}


Args Args::read(int argc, char** argv)
{
    Args args;
    for (int i = 1; i < argc; i++)
    {// desired input settings
        if (string(argv[i]) == "--make_gray") args.make_gray = (string(argv[++i]) == "true");
        else if (string(argv[i]) == "--resize_src") args.resize_src = (string(argv[++i]) == "true");
        else if (string(argv[i]) == "--width") args.width = atoi(argv[++i]);
        else if (string(argv[i]) == "--height") args.height = atoi(argv[++i]);

        else if (string(argv[i]) == "--hit_threshold")
        {
            args.hit_threshold = atof(argv[++i]);
            args.hit_threshold_auto = false;
        }
        else if (string(argv[i]) == "--scale") args.scale = atof(argv[++i]);
        else if (string(argv[i]) == "--nlevels") args.nlevels = atoi(argv[++i]);
        else if (string(argv[i]) == "--win_width") args.win_width = atoi(argv[++i]);
        else if (string(argv[i]) == "--win_stride_width") args.win_stride_width = atoi(argv[++i]);
        else if (string(argv[i]) == "--win_stride_height") args.win_stride_height = atoi(argv[++i]);
        else if (string(argv[i]) == "--gr_threshold") args.gr_threshold = atoi(argv[++i]);
        else if (string(argv[i]) == "--gamma_correct") args.gamma_corr = (string(argv[++i]) == "true");
        else if (string(argv[i]) == "--write_video") args.write_video = (string(argv[++i]) == "true");
        else if (string(argv[i]) == "--dst_video") args.dst_video = argv[++i];
        else if (string(argv[i]) == "--dst_video_fps") args.dst_video_fps = atof(argv[++i]);
        else if (string(argv[i]) == "--help") printHelp();
        else if (string(argv[i]) == "--txt_gen") txtGenerator(argc, argv) ;

        else if (string(argv[i]) == "--video") { args.src = argv[++i]; args.src_is_video = true; }
        else if (string(argv[i]) == "--camera") { args.camera_id = atoi(argv[++i]); args.src_is_camera = true; }
        else if (args.src.empty()) args.src = argv[i];
        else throw runtime_error((string("unknown key: ") + argv[i]));
    }
    return args;
}

/**
	Controls
	
	The default values for training are shown between braces.

	Hence the flags for training are: --scale 1.12 --nlevels 3 --gr_threshold 0 --hit_threshold 0

	-HOG scale (1.12):
		Scaling factor between two successive ROI window sizes.

	-Levels count (13):
		Maximal size of the ROI window. The detector searches using every size from 1 up to that value.

	-HOG group threshold (0):
		Post-detection grouping of the ROI.

	-Hit threshold (0):
		Displaces the mathematic decision surface of the SVM model.
*/

App::App(const Args& s)
{
    cv::gpu::printShortCudaDeviceInfo(cv::gpu::getDevice());

    args = s;
    cout << "\nControls:\n"
         << "\tESC - exit\n"
         << "\tm - change mode GPU <-> CPU\n"
         << "\tg - convert image to gray or not\n"
         << "\t1/q - increase/decrease HOG scale\n"
         << "\t2/w - increase/decrease levels count\n"
         << "\t3/e - increase/decrease HOG group threshold\n"
         << "\t4/r - increase/decrease hit threshold\n"
         << endl;

    use_gpu = true; // set as deafult to use gpu not cpu
    make_gray = args.make_gray;
    scale = args.scale;
    gr_threshold = args.gr_threshold;
    nlevels = args.nlevels;
                            // copying the inputs to the variables
    if (args.hit_threshold_auto)
        args.hit_threshold = args.win_width == 48 ? 1.4 : 0;
    hit_threshold = args.hit_threshold;

    gamma_corr = args.gamma_corr;
/*
    if (args.win_width != 64 && args.win_width != 48)
        args.win_width = 64;*/

    cout << "Scale: " << scale << endl;
    if (args.resize_src) // incase image resize is requested as an input then print the other parameters
        cout << "Resized source: (" << args.width << ", " << args.height << ")\n";
    cout << "Group threshold: " << gr_threshold << endl;
    cout << "Levels number: " << nlevels << endl;
    cout << "Win width: " << args.win_width << endl;
    cout << "Win stride: (" << args.win_stride_width << ", " << args.win_stride_height << ")\n";
    cout << "Hit threshold: " << hit_threshold << endl;
    cout << "Gamma correction: " << gamma_corr << endl;
    cout << endl;
}


void App::run()
{

    // Shah modification replaces below to load detecor in yml file
    // replace commented code below
    FileStorage fs("../../data/carDetector56x48.yml", FileStorage::READ);


    int width, height;
    vector<float> detector;
    fs["width"] >> width;
    fs["height"] >> height;
    fs["detector"] >> detector;
    /* loads the detector information from the .yml file (note the .yml file contains
     also the .yml file contain the values for the width and the height and they are read into variables but into the conflicting copy)*/
    fs.release();


    // automatically set size from yaml file
    Size win_size(width,height); //(64, 128) or (48, 96) or 56,48
    Size win_stride(args.win_stride_width, args.win_stride_height);

    // original code
    running = true;
    cv::VideoWriter video_writer;

//     Size win_size(args.win_width, args.win_width * 2); //(64, 128) or (48, 96)
//     Size win_stride(args.win_stride_width, args.win_stride_height);

    // Create HOG descriptors and detectors here
//     vector<float> detector;
//     if (win_size == Size(64, 128))
//         detector = cv::gpu::HOGDescriptor::getPeopleDetector64x128();
//     else
//         detector = cv::gpu::HOGDescriptor::getPeopleDetector48x96();


    // non-modified code
    cv::gpu::HOGDescriptor gpu_hog(win_size, Size(16, 16), Size(8, 8), Size(8, 8), 9,
                                   cv::gpu::HOGDescriptor::DEFAULT_WIN_SIGMA, 0.2, gamma_corr,
                                   cv::gpu::HOGDescriptor::DEFAULT_NLEVELS);
    cv::HOGDescriptor cpu_hog(win_size, Size(16, 16), Size(8, 8), Size(8, 8), 9, 1, -1,
                              HOGDescriptor::L2Hys, 0.2, gamma_corr, cv::HOGDescriptor::DEFAULT_NLEVELS);

    // Shah modification replaces code below
    gpu_hog.setSVMDetector(detector);// set the detector with the detector values from the .yml file
    cpu_hog.setSVMDetector(detector); // this detector is not compatible with our detector files

    // original code
//     gpu_hog.setSVMDetector(detector);
//     cpu_hog.setSVMDetector(detector);

    while (running)
    {
        VideoCapture vc;
        Mat frame;

        if (args.src_is_video)// if the input is a video
        {
            vc.open(args.src.c_str());
            if (!vc.isOpened())
                throw runtime_error(string("can't open video file: " + args.src));
            vc >> frame;
        }
        else if (args.src_is_camera)// if the input is from a camera
        {
            vc.open(args.camera_id);
            if (!vc.isOpened())
            {
                stringstream msg;
                msg << "can't open camera: " << args.camera_id;
                throw runtime_error(msg.str());
            }
            vc >> frame;
        }
        else // in case the input is just an image
        {
            frame = imread(args.src);
            if (frame.empty())
                throw runtime_error(string("can't open image file: " + args.src));
        }

        Mat img_aux, img, img_to_show;
        gpu::GpuMat gpu_img;
        // Iterate over all frames
        while (running && !frame.empty())// as long as running is set to be true and we still have frames to run then
        {
            workBegin(); // start timer of the whole work

            // Change format of the image
            if (make_gray) cvtColor(frame, img_aux, CV_BGR2GRAY); // if itś set to move into grey scale then do so
            else if (use_gpu) cvtColor(frame, img_aux, CV_BGR2BGRA);
            else frame.copyTo(img_aux);

            // Resize image
            if (args.resize_src) resize(img_aux, img, Size(args.width, args.height));
            else img = img_aux;
            img_to_show = img;

            gpu_hog.nlevels = nlevels;
            cpu_hog.nlevels = nlevels;

            vector<Rect> found;

            // Perform HOG classification
            hogWorkBegin();// start the timer of the hog classification
            if (use_gpu)
            {
                gpu_img.upload(img);
                gpu_hog.detectMultiScale(gpu_img, found, hit_threshold, win_stride,
                                         Size(0, 0), scale, gr_threshold);
                // if use_gpu is true so itś required to use gpu then use the detect multi scale function in the gpu_hog
            }
            else cpu_hog.detectMultiScale(img, found, hit_threshold, win_stride,
                                          Size(0, 0), scale, gr_threshold);
                // if use_gpu is false then itś required to use the cpu then we use the detectmultiscale function of the cpu_hog
                /* based on the produced output alternation when the mode is toggled between cpu and gpu although the thresholds didn change so it could
                    be infered from the alternation in the output that detectmulti scale works differently depending on whether its from cpu_hog or gpu_hog */
            hogWorkEnd();// end the timer of the hog classification

            // Draw positive classified windows  here we draw the green rectangular boxes of the found objects
            for (size_t i = 0; i < found.size(); i++)
            {


                Rect r = found[i]; // what should be saved as suggest in a .yml file by the detector.cpp file

                detector_out(&r);

                rectangle(img_to_show, r.tl(), r.br(), CV_RGB(0, 255, 0), 3);

            }

            if (use_gpu) // here the text is added (fps) to the display both in case of cpu or gpu
                putText(img_to_show, "Mode: GPU", Point(5, 25), FONT_HERSHEY_SIMPLEX, 1., Scalar(255, 100, 0), 2);
            else
                putText(img_to_show, "Mode: CPU", Point(5, 25), FONT_HERSHEY_SIMPLEX, 1., Scalar(255, 100, 0), 2);
            putText(img_to_show, "FPS (HOG only): " + hogWorkFps(), Point(5, 65), FONT_HERSHEY_SIMPLEX, 1., Scalar(255, 100, 0), 2);
            putText(img_to_show, "FPS (total): " + workFps(), Point(5, 105), FONT_HERSHEY_SIMPLEX, 1., Scalar(255, 100, 0), 2);
            imshow("opencv_gpu_hog", img_to_show);

            if (args.src_is_video || args.src_is_camera) vc >> frame;// whether the source is video or from came put update the frame to the capured value

            workEnd(); // end the timer of the whole work

            if (args.write_video)
            {
                if (!video_writer.isOpened())
                {
                    video_writer.open(args.dst_video, CV_FOURCC('x','v','i','d'), args.dst_video_fps,
                                      img_to_show.size(), true);
                    if (!video_writer.isOpened())
                        throw std::runtime_error("can't create video writer");
                }

                if (make_gray) cvtColor(img_to_show, img, CV_GRAY2BGR);
                else cvtColor(img_to_show, img, CV_BGRA2BGR);

                video_writer << img;
            }
                // produce an output video from the results
            handleKey((char)waitKey(3));
        }
    }
}


void App::handleKey(char key)
{
    switch (key)
    {
    case 27:
        running = false;
        break;
    case 'm':
    case 'M':
        use_gpu = !use_gpu;
        cout << "Switched to " << (use_gpu ? "CUDA" : "CPU") << " mode\n";
        // toggle between modes cpu and gpu by pressing m
        break;
    case 'g':
    case 'G':
        make_gray = !make_gray;
        cout << "Convert image to gray: " << (make_gray ? "YES" : "NO") << endl;
        // toggle between gray or not by pressing g
        break;
    case '1':
        scale *= 1.11;
        cout << "Scale: " << scale << endl;
        // increase the scale by 11% when digit 1 is pressed
        break;
    case 'q':
    case 'Q':
        scale /= 1.11;
        cout << "Scale: " << scale << endl;
        // decrease the scale by 11% when q is pressed
        break;
    case '2':
        nlevels++;
        cout << "Levels number: " << nlevels << endl;
        // increment the max number of HOG window scales when digit 2 is pressed
        break;
    case 'w':
    case 'W':
        nlevels = max(nlevels - 1, 1);
        cout << "Levels number: " << nlevels << endl;
        // decrement the max number of HOG window scales but also ensuring itś minimum value is 1 when w is pressed
        break;
    case '3':
        gr_threshold++;
        cout << "Group threshold: " << gr_threshold << endl;
        // merging similar rects constant (group threshold) incrementation when digit 3 is pressed
        break;
    case 'e':
    case 'E':
        gr_threshold = max(0, gr_threshold - 1);
        cout << "Group threshold: " << gr_threshold << endl;
        // merging similar rects constant (group thershold) decrementation but also making sure that itś minimum value is 0 when e is pressed
        break;
    case '4':
        hit_threshold+=0.05;
        cout << "Hit threshold: " << hit_threshold << endl;
        // classifying plane distance threshold (0.0 usually)"hit threshold" increment  by 0.05 when digit 4 is pressed
        break;
    case 'r':
    case 'R':
        hit_threshold = hit_threshold - 0.05;
        cout << "Hit threshold: " << hit_threshold << endl;
        // classifying plane distance threshold (0.0 usually)"hit threshold" decrement  by 0.05 when r is pressed
        break;
    case 'c':
    case 'C':
        gamma_corr = !gamma_corr;
        cout << "Gamma correction: " << gamma_corr << endl;
        // toggle the gamma correction variable when c is pressed
        break;
    }
}


inline void App::hogWorkBegin() { hog_work_begin = getTickCount(); }

inline void App::hogWorkEnd()
{
    int64 delta = getTickCount() - hog_work_begin;
    double freq = getTickFrequency();
    hog_work_fps = freq / delta;
}

inline string App::hogWorkFps() const
{// only the hog classification working fps
    stringstream ss;
    ss << hog_work_fps;
    return ss.str();
}


inline void App::workBegin() { work_begin = getTickCount(); }

inline void App::workEnd()
{
    int64 delta = getTickCount() - work_begin;
    double freq = getTickFrequency();
    work_fps = freq / delta;
}

inline string App::workFps() const
{// the working fps of the run
    stringstream ss;
    ss << work_fps;
    return ss.str();
}

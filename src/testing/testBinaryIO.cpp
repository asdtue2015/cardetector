#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <iomanip>
#include <stdexcept>


using namespace std;


//
//
// Test binary IO through YAML
//
//
int main( void )
{
  // open test file
  ofstream fid;
  fid.open("testBinaryIO.yml");

  // test vars
  int nlevels = 1;
  int block_size_width = 16, block_size_height = 16;
  int block_stride_width = 8, block_stride_height = 8;
  int cell_size_width = 8, cell_size_height = 8;
  int nbins = 9;
  int block_hist_sz = 36;
  int level = 1;
  int blocksperimg_width  = 152;
  int blocksperimg_height = 45;
  int elements = 246240;
  float scale = 1.;
  int width  = 1224;
  int height = 370;
  float data[100] = {6.228627e-04, 3.554542e-04, 7.556518e-04, 5.501414e-04, 3.177491e-04, 4.082096e-04, 5.116533e-04, 7.709789e-04, 2.240671e-04, 4.842518e-04, 3.294572e-05, 5.061261e-04, 1.738248e-05, 5.835844e-04, 3.668455e-05, 7.338518e-04, 5.602434e-05, 3.335758e-04, 7.107264e-05, 5.801551e-04, 2.932783e-04, 5.469469e-04, 4.638547e-04, 3.136157e-04, 2.157868e-04, 7.231463e-04, 9.468608e-04, 1.645211e-04, 5.867034e-04, 5.535629e-04, 7.077159e-04, 4.931316e-04, 6.965248e-04, 8.314229e-05, 6.174281e-04, 8.025287e-04, 1.052049e-04, 4.694092e-04, 7.197478e-04, 1.354036e-04, 7.884075e-04, 4.267136e-04, 7.687038e-04, 7.511160e-04, 5.833666e-04, 8.435122e-04, 7.833278e-04, 2.008200e-04, 4.036428e-04, 1.484840e-04, 5.452247e-04, 5.209702e-04, 9.116175e-04, 2.581779e-04, 9.941580e-04, 3.884114e-04, 4.939162e-04, 2.001367e-04, 4.413747e-04, 8.439139e-04, 3.489596e-04, 7.313590e-04, 6.599741e-04, 9.050071e-04, 4.753098e-05, 5.804313e-04, 5.343152e-04, 3.570757e-05, 4.379132e-04, 6.750957e-04, 5.441469e-04, 3.726113e-04, 2.713846e-06, 2.553874e-04, 1.038717e-04, 5.680799e-04, 9.458009e-04, 9.956279e-05, 2.033033e-04, 9.051244e-04, 1.717711e-04, 4.038876e-04, 1.769315e-04, 1.194155e-04, 3.927205e-04, 5.476250e-04, 4.273057e-04, 3.341282e-04, 3.019493e-04, 7.133063e-04, 8.322092e-04, 2.830037e-04, 4.202540e-04, 9.578022e-04, 3.770386e-04, 9.615942e-04, 7.982608e-04, 9.173010e-04, 5.437323e-04, 3.292272e-04}; 
    
  // write header data  
  fid << "%YAML:1.0"                          << endl;
  fid << "Levels: "          << nlevels       << endl;
  fid << "Block size: [ "    << block_size_width   << ", " << block_size_height   <<" ]"<< endl;
  fid << "Block stride: [ "  << block_stride_width << ", " << block_stride_height <<" ]"<< endl;
  fid << "Cell size: [ "     << cell_size_width    << ", " << cell_size_height    <<" ]"<< endl;
  fid << "nbins: "           << nbins         << endl;
  fid << "block hist size: " << block_hist_sz << endl;
    
  fid << "Level1: " << level << endl;
  fid << "blocksperimg1: [ " << blocksperimg_width << ", " << blocksperimg_height << " ]" << endl;
  fid << "Elements1: " << elements << endl;
  fid << "Scale1: " << scale << endl;
  fid << "Width1: " << width << endl;
  fid << "Height1: " << height << endl;
  fid << "Features1: [STARTBINARY";

  // write data in binary format
  char* raw = (char*)data;
  for (unsigned int i = 0; i < 100*sizeof(float); i++ )
  {
    fid << raw[i];
  }
    
  fid << "ENDBINARY]" << endl;
  fid.close();

}
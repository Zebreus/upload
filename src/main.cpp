#include "settings.hpp"
#include <vector>
#include "file.hpp"
#include "loader.hpp"
#include "uploader.hpp"
#include "logger.hpp"

int main(int argc , char** argv){
  Settings settings(argc, argv);
  
  std::vector<File> files = loadFiles(settings);
  
  Uploader uploader(settings);
  
  for(const File& file : files){
    logger.log(Logger::Url) << uploader.uploadFile(file) << std::endl;
  }
  return 0;
}

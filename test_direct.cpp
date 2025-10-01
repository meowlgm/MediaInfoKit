#include "MediaInfoDLL/MediaInfoDLL.h"
#include <iostream>
#include <string>

using namespace MediaInfoDLL;

int main() {
    MediaInfo MI;
    
    std::wstring filename = L"/Users/meowlgm/Downloads/MediaInfoKit/Whisper.m4a";
    
    size_t result = MI.Open(filename);
    
    if (result) {
        std::wcout << L"File opened successfully!" << std::endl;
        std::wstring info = MI.Inform();
        std::wcout << info << std::endl;
        MI.Close();
        return 0;
    } else {
        std::wcerr << L"Failed to open file!" << std::endl;
        return 1;
    }
}


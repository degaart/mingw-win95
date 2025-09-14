#include <iostream>
#include <chrono>

int main()
{
    auto now = std::chrono::system_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch()).count();
    std::cout << "Seconds since epoch: " << duration << "\n";
    return 0;
}


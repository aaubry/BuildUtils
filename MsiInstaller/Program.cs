using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MsiInstaller
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length != 1)
            {
                Console.WriteLine("Usage: MsiInstaller <filename.msi>");
                return;
            }

            var logFile = Path.GetTempFileName();
            Console.WriteLine(logFile);

            var poller = new Thread(() => TailFile(logFile));
            poller.Start();

            var msiexec = Process.Start(new ProcessStartInfo
            {
                FileName = "msiexec.exe",
                Arguments = string.Format("/qn /lwei+! \"{0}\" /i \"{1}\"", logFile, args[0]),
                CreateNoWindow = true,
                UseShellExecute = false,
            });

            msiexec.WaitForExit();
            processHasExited = true;

            poller.Join();

            File.Delete(logFile);
        }

        private static volatile bool processHasExited;

        private static void TailFile(string fileName)
        {
            while (!File.Exists(fileName))
            {
                Thread.Sleep(100);
            }

            using (var stream = File.Open(fileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                using (var reader = new StreamReader(stream))
                {
                    var lastReadTime = DateTime.Now;
                    while (true)
                    {
                        var buffer = new char[100];

                        int count = reader.Read(buffer, 0, buffer.Length);
                        if (count > 0)
                        {
                            Console.Write(buffer, 0, count);
                            lastReadTime = DateTime.Now;
                        }
                        else
                        {
                            if (processHasExited && DateTime.Now.Subtract(lastReadTime).TotalSeconds > 3)
                            {
                                break;
                            }
                            Thread.Sleep(30);
                        }
                    }
                }
            }
        }
    }
}

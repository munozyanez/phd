#include <iostream>
#include <fstream>
#include "Cia402device.h"
#include "SocketCanPort.h"

#include "math.h"

#include "SerialArduino.h"

#include "fcontrol.h"
#include "IPlot.h"
#include "OnlineSystemIdentification.h"

#include "Kinematics.h"


/// IEEE Access paper experimental code
/// Performs all experiments used in the paper and
/// stores all data in .csv files

// It requires: -Platform inclination=0
//              -Reset IMU sensor

long AdaptiveStep(double target, double time);

int main (){

    //--sensor--
    SerialArduino imu;
    double imuIncli=0,filtIncli=0,imuOrien,filtIncliOld=0;
    SystemBlock imuFilter(0.09516,0,- 0.9048,1); //w=5

    //    sleep(4); //wait for sensor

    ofstream sysdatanum("/home/humasoft/Escritorio/idsysnum000.csv",std::ofstream::out);
    ofstream sysdataden("/home/humasoft/Escritorio/idsysden000.csv",std::ofstream::out);
    ofstream condata("/home/humasoft/Escritorio/idcon000.csv",std::ofstream::out);
    ofstream sysdatamp("/home/humasoft/Escritorio/idsensor000response.csv",std::ofstream::out);
    ofstream timeresp("/home/humasoft/Escritorio/id000response.csv",std::ofstream::out);


    //Samplinfg time
    double dts=0.025; //
    SamplingTime Ts(dts);

    /// System identification
    double wf=1;

    SystemBlock filterSensor(wf*dts,wf*dts,wf*dts-2,2+wf*dts); //w*dts*(z+1)/(z*(2+w*dts)+(w*dts-2));
    SystemBlock filterSignal(wf*dts,wf*dts,wf*dts-2,2+wf*dts); //w*dts*(z+1)/(z*(2+w*dts)+(w*dts-2));
//    SystemBlock filterMag(wf*dts,wf*dts,wf*dts-2,2+wf*dts); //w*dts*(z+1)/(z*(2+w*dts)+(w*dts-2));
//    SystemBlock filterPhi(wf*dts,wf*dts,wf*dts-2,2+wf*dts); //w*dts*(z+1)/(z*(2+w*dts)+(w*dts-2));

    ulong numOrder=0,denOrder=2;
    SystemBlock filter(wf*dts,wf*dts,wf*dts-2,2+wf*dts); //w*dts*(z+1)/(z*(2+w*dts)+(w*dts-2));
    OnlineSystemIdentification model(numOrder, denOrder, filter, 0.95, 0.95, 30 );

    vector<double> num(numOrder+1),den(denOrder+1); //(order 0 also counts)
//    SystemBlock integral(0,1,-1,1);
    vector<SystemBlock> sys = {SystemBlock(num,den)}; //the resulting identification
//    double sysk=0, syskAverage=0.1;



    ///Controller and tuning
//    FPDBlock con(0,0,0,dts);
//    FPDBlock con(0.15,0.03,0.75,dts);
    FPDBlock scon(0.2342,0.7370,-0.59,dts);
    FPDBlock con(0.23,0.36,-0.6,dts);

    double wgc=3;
//    FPDTuner tuner ( 100, wgc, dts);//ok second order (0,2)+integrator derivative control unstable
    FPDTuner tuner ( 50, wgc, dts);//ok second order (0,2)+integrator integral control


    PIDBlock intcon(0.2547,0.7730,0,dts);
    //double phi,mag,w=1;


    ///Motor command
    //  data << "Controller PID" << " , " << " 0.1,0.05,0,dts "<< endl;

    //m1 setup
    SocketCanPort pm31("can1");
    CiA402SetupData sd31(2048,24,0.001, 0.144, 20);
    CiA402Device m1 (31, &pm31, &sd31);
    m1.Reset();
    m1.SwitchOn();
    //    m1.SetupPositionMode(10,10);
    m1.Setup_Velocity_Mode(20);
    //  m1.Setup_Torque_Mode();


    IPlot id;


    //tilt sensor initialization
    for (double t=0; t<6; t+=10*dts)
    {
        if (imu.readSensor(imuIncli,imuOrien)>=0) break;
        cout << "Initializing sensor! " ;

    }

    //initialize model
    vector<double> theta={-1.0246, 0.0248015, 0.133564};
    model.SetParamsVector(theta);

    double psr; //pseudorandom
    double tinit=300; //in seconds
    double incli=5, error=0, cs=0;

    double kp = 0.0,kd = 0.0,fex = 0.0;
    double smag = 0.0,sphi = 0.0;
    double sysk=0;

    con.GetParameters(kp,kd,fex);

    //populate system matrices
    for (double t=0;t<tinit; t+=dts)
    {
        psr=+5*( 1+0.5*( sin(wgc*t) + sin(10*wgc*t) ) + 0.1*(0+(rand() % 10)-5) ); //pseudorandom
        if (imu.readSensor(imuIncli,imuOrien) <0)
        {
            cout << "Initializing sensor! ";
            //Sensor error, do nothing.
            cout << "Inc: " << imuIncli << " ; Ori: "  << imuOrien << endl;
        }
        else
        {
            filtIncliOld=filtIncli;
            filtIncli=(imuIncli>filterSensor);
            //Compute error
            error=(psr+incli)-imuIncli;
            //        cout << "incli: " << incli << " ; imuIncli: "  << imuIncli << endl;
            //Controller command
            cs = error > scon;
            m1.SetVelocity(cs);
            //update Model
//            if(abs((cs))>0.1)
//            if( abs(filtIncli-filtIncliOld) > 0.1)
            {
                model.UpdateSystem(cs, imuIncli);
//                cout << "cs: " << cs << " ; imuIncli: "  << imuIncli << endl;
            }
//            model.UpdateSystem(cs, imuIncli);
            model.GetSystemBlock(sys[0]);
        }
        sysk=sys[0].GetZTransferFunction(num,den);
        sys[0].GetMagnitudeAndPhase(dts,wgc,smag,sphi);

        condata << t << ", " << kp << ", " << kd << ", " << fex   << endl;
        sysdatamp << t << ", " << smag << ", " << (sphi) <<  endl;
        timeresp << t << ", " << filtIncli << ", " << m1.GetPosition() <<  endl;

        sysdatanum << t;
        sysdatanum << ", " << num.back();
        for (int i=num.size()-1; i>=0; i--)
        {
            sysdatanum << ", " << sysk*num[i];
        }
        sysdatanum << endl;

        sysdataden << t;
        sysdataden << ", " << den.back();
        for (int i=den.size()-1; i>=0; i--)
        {
            sysdataden << ", " << den[i];

        }
        sysdataden << endl;
        //        sysdatanum << ", " << smag << ", " << sphi;

//        cout << t << ", " << kp << ", " << kd << ", " << fex   << endl;

        Ts.WaitSamplingTime();
    }








    //  m1.SetPosition(0);
    //  m2.SetPosition(0);
    //  m3.SetPosition(0);
    //  sleep (1);
    //  m1.SetPosition(0);
    m1.SetVelocity(0);
    //  sleep (3);
    m1.SwitchOff();
    //  m3.SetPosition(0);

    sysdatanum.close();
    sysdataden.close();

    condata.close();

    timeresp.close();


    return 0;

}




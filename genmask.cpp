#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main () {
	ofstream fout("emails_mask.inc");

	fout << "mask:" << endl;

	for (int x=0 ; x<256 ; x++) {
		fout << "db ";

		int m=0;

		// space char
		if (x == ':' || x ==' ' || x == 0x0D || x == 0x0A || x == 0x09 ) {
			m+=1;
		}

		// login char
		string spc("!#$%&'*+-/=?^_`{|}~");
		if ( ('a'<=x && x <= 'z') || ('A'<=x && x <= 'Z') || ('0'<=x && x <= '9') || spc.find(x) != string::npos) {
			m+=2;
		}

		// host char
		if ( ('a'<=x && x <= 'z') || ('A'<=x && x <= 'Z') || ('0'<=x && x <= '9')) {
			m+=4;
		}

		if ( x=='-' || x=='.' ) {
			m+=8;
		}


		fout << m << endl;
	}

	fout.close();
	return 0;
}
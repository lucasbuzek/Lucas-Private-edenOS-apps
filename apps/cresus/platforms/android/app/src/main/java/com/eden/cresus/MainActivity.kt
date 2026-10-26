package com.eden.cresus

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState) { setContent { CresusRoot() } }
    }
}

@Composable
fun CresusRoot() {
    var tab by remember { mutableIntStateOf(0) }
    val names=listOf("Research","Portfolio","ZACCHAEUS","Lab")
    Scaffold(bottomBar={ NavigationBar { names.forEachIndexed { i,n -> NavigationBarItem(selected=tab==i,onClick={tab=i},icon={},label={Text(n)}) } } }) { pad ->
        Column(Modifier.padding(pad).padding(20.dp)) {
            Text("CRESUS", style=MaterialTheme.typography.headlineLarge)
            Text(names[tab], style=MaterialTheme.typography.titleLarge)
            Spacer(Modifier.height(16.dp))
            if(tab==0) {
                OutlinedTextField(value="",onValueChange={},label={Text("Company, security or question")})
                Spacer(Modifier.height(12.dp))
                Text("Alpha: all implemented capabilities are unlocked for testing.")
            } else Text("Alpha workspace")
        }
    }
}

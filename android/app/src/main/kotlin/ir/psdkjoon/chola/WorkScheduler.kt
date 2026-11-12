package ir.psdkjoon.chola

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ListenableWorker
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

object WorkScheduler {
    private const val MIN_MINUTES = 15L
    private const val KEY_JOB = "job"

    private val handlers = ConcurrentHashMap<String, (Context) -> Unit>()

    fun register(job: String, handler: (Context) -> Unit) {
        handlers[job] = handler
    }

    fun schedule(
        context: Context,
        job: String,
        everyMinutes: Long,
        requiresNetwork: Boolean = false,
    ) {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(
                if (requiresNetwork) NetworkType.CONNECTED else NetworkType.NOT_REQUIRED,
            )
            .build()
        val request = PeriodicWorkRequest.Builder(
            PeriodicWorker::class.java,
            everyMinutes.coerceAtLeast(MIN_MINUTES),
            TimeUnit.MINUTES,
        )
            .setConstraints(constraints)
            .setInputData(androidx.work.Data.Builder().putString(KEY_JOB, job).build())
            .build()
        WorkManager.getInstance(context.applicationContext)
            .enqueueUniquePeriodicWork(job, ExistingPeriodicWorkPolicy.UPDATE, request)
    }

    fun cancel(context: Context, job: String) {
        WorkManager.getInstance(context.applicationContext).cancelUniqueWork(job)
    }

    internal fun run(context: Context, job: String?): ListenableWorker.Result {
        val handler = job?.let { handlers[it] } ?: return ListenableWorker.Result.failure()
        return try {
            handler(context)
            ListenableWorker.Result.success()
        } catch (_: Exception) {
            ListenableWorker.Result.retry()
        }
    }

    internal const val JOB_KEY = KEY_JOB
}

class PeriodicWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        return WorkScheduler.run(applicationContext, inputData.getString(WorkScheduler.JOB_KEY))
    }
}
